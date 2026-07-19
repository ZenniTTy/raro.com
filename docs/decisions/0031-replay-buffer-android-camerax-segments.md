# ADR-0031 — Replay buffer Android via segmentos rotativos CameraX + concat sem re-encode

- Status: Proposto (condicionado a spike-gate no M54)
- Data: 2026-07-18
- Decisor: dono do produto (Eduardo)

## Contexto

O Raro Replay (pré-roll de 15/30s embutido no REC) funciona no iOS via ring buffer de chunks `.mp4` de 1s escritos por `AVAssetWriter`, concatenados no STOP por `exportCombined` (`ReplayBuffer.swift`). No Android a feature é stub (`ReplayBufferHostApiImpl` lança `UnsupportedOperationException`; `CameraManager.includeReplayPreroll` é ignorado com `Log.w`). É a **Fatia 5/5 pré-APK** e a última pendência de paridade antes do APK do cliente.

O ADR-0030 e o Blueprint (linha 55) **reservaram `MediaCodec` + `MediaMuxer` para o replay buffer** — a premissa era que o buffer circular exige acesso a frames em tempo real, que o CameraX `Recorder` não dá. Este ADR **revisita essa premissa**: pesquisa em fonte primária (developer.android.com, release notes CameraX 1.6/1.7, tabela de stream configs camera2, sample grafika) confirmou que o `Recorder` de fato não expõe samples — mas mostrou que existe uma rota que atinge o pré-roll **sem** reescrever o pipeline nativo já provado nas Fatias 1-3 (preview COMPATIBLE, `bindIfReady`, tap-focus, voz→gravação, 4K real no M54).

## Opções consideradas

1. **Rota D — segmentos rotativos CameraX + concat sem re-encode** (esta decisão)
   - O `Recorder` grava continuamente **segmentos curtos rotativos** em `cacheDir` (ring de arquivos, espelhando o ring de chunks do iOS). No REC, congela o ring, grava a gravação principal, e no STOP concatena `[segmentos da janela] + [gravação principal]` via `MediaExtractor` + `MediaMuxer` (**sem re-encode**, sem dependência nova).
   - Prós: preserva 100% do pipeline nativo provado (não retesta preview/foco/4K/voz); zero dependência nova; lógica fica em cima do stack atual (Kotlin + APIs de plataforma); fallback trivial (concat falhou → entrega a gravação principal).
   - Contras: **não é o padrão canônico** de ring buffer Android (o canônico é MediaCodec, opção 2); introduz emendas internas no pré-roll (uma por segmento) — cada troca de `Recording` tem um gap não documentado; corte preciso só em keyframe; concat sem re-encode exige bitstreams idênticos (SPS/PPS) e emendas de AAC podem estalar.
2. **Rota C — camera2 + MediaCodec Surface + ring circular** (o que o ADR-0030/Blueprint previam; padrão grafika `CircularEncoderBuffer`)
   - Prós: padrão canônico; frames contínuos (zero emenda interna no pré-roll); paridade máxima com o desenho iOS.
   - Contras: **reescreve o pipeline nativo Android inteiro** (tee OpenGL da SurfaceTexture da câmera p/ preview + encoder; gestão de PTS/keyframe/muxer manual) — descarta e obriga a re-testar tudo que foi provado nas Fatias 1-3; RAM de 4K em buffer (~187-262 MB/30s) força downgrade do buffer p/ 1080p. Alto risco e custo.
3. **Rota B — segmentar o `Recording` do CameraX sem ring próprio; Rota A — 2º VideoCapture** — A morta por doc (2ª instância de VideoCapture não é suportada); B é essencialmente a Rota D sem o ring explícito, sem vantagem.

## Decisão

**Rota D**, com **spike-gate bloqueante no M54 como 1º passo** — antes de qualquer bridge ou UI. Isto **substitui** a reserva "replay = MediaCodec+MediaMuxer" do ADR-0030/Blueprint para o caso do **pré-roll linear** (o buffer não precisa de frames em tempo real; precisa de segmentos concatenáveis). `MediaCodec` só volta a ser exigido se o spike reprovar (→ Rota C, que exigiria um ADR próprio de reescrita de pipeline).

### Spike-gate (bloqueante) — critérios de aprovação

Medido no Galaxy M54 físico, com `ffprobe` nos artefatos puxados do device:

1. **Gap por emenda ≤ ~150ms** — ciclar `Recording` em segmentos e medir, via PTS/duração de áudio+vídeo de segmentos consecutivos, o buraco A/V em CADA troca (não só na primeira). Uma janela de 15s em chunks de 5s tem 2-3 emendas internas — o gap acumulado importa.
2. **Gap no instante do REC ≤ ~150ms** — o buraco entre parar o último segmento do ring e iniciar a gravação principal (o pior lugar para perder tempo — é o momento da ação).
3. **Bitstreams concatenáveis** — `ffprobe` comprova `extradata`/SPS-PPS e `codec/profile/level/sample_rate/channels` IDÊNTICOS entre segmentos e gravação principal (pré-condição do concat sem re-encode).
4. **Concat de 3+ segmentos reproduzível** — não só 2: provar que a emenda múltipla toca na galeria SEM artefato grosseiro de vídeo, e **ouvir** a emenda de áudio (estalo de AAC priming não aparece em número).

Reprovou qualquer critério → **parar e reavaliar** (Rota C vira ADR próprio). NÃO empilhar fixes sobre um gap estrutural (lição Vosk/SFSpeech, memória `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`).

## Consequências

- **Atualiza o Blueprint (linha 55) e revisa o ADR-0030:** o replay buffer Android passa a usar CameraX Recorder segmentado + concat, NÃO MediaCodec+MediaMuxer, condicionado ao spike. MediaCodec permanece documentado como Rota C / plano B.
- Contrato Pigeon `ReplayBufferHostApi`/`ReplayBufferFlutterApi` **INALTERADO** (`enableReplayBuffer`/`disableReplayBuffer`/`saveReplay`/`onReplaySaved`/`onReplayFailed` já existem). Camada Dart (`ReplayBufferController`, estados, `camera_screen` com `includeReplayPreroll`) **INALTERADA** — já funciona, só falta o nativo Android responder.
- `saveReplay()` standalone é **implementado de verdade** no host (reusa o `ReplayConcat` do pré-roll) mas **não-exposto na UI** (paridade: o iOS também não tem botão hoje) — decisão do dono 2026-07-18. O gatilho de UI é feature futura das 2 plataformas.
- Concat DEVE **tolerar segmento faltando/corrompido** (cacheDir é efêmero — o SO pode evictar; memória `raro-pattern-android-thumbnail-vault-not-cachedir`): janela degrada graciosamente, o clipe NUNCA falha por causa disso.
- Prova objetiva de formato exigida (gate §10): `ffprobe` no MP4 final comprovando duração ≈ janela+REC e A/V contínuos.

## Referências

- Spec: `docs/superpowers/specs/2026-07-18-replay-buffer-android-design.md`
- ADR-0030 (gravação linear Android — a premissa "replay = MediaCodec" que este ADR revisa)
- iOS: `ReplayBuffer.swift` (ring de chunks 1s + `exportCombined`), `CameraManager.swift:396-442` (pause/preroll/resume)
- Memórias: `raro-pattern-android-mediacodec-buffer-management`, `raro-pattern-android-thumbnail-vault-not-cachedir`, `raro-preroll-rec-design-s2c`, `feedback_many_native_fixes_means_reread_logs_not_abandon_framework`
- Pesquisa (fonte primária, 2026-07-18): CameraX release notes 1.6/1.7; camera2 `CameraDevice` guaranteed stream configs; `MediaExtractor`/`MediaMuxer` docs; grafika `CircularEncoderBuffer.java`
