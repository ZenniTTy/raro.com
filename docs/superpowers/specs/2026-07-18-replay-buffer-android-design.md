# Spec — Raro Replay (pré-roll) no Android — Fatia 5/5 pré-APK

> Data: 2026-07-18 · Status: design aprovado pelo dono (condicionado a spike-gate)
> Última fatia do pacote pré-APK. Fecha a paridade Android↔iOS antes do APK do cliente.
> Decisão de rota e critérios do gate: **ADR-0031**.

## 1. Estado atual (mapeado 2026-07-18)

- **iOS: funciona.** Ring de chunks `.mp4` de 1s (`AVAssetWriter`) em `ReplayBuffer.swift`; no REC o buffer é congelado (`pauseAppending`), a gravação principal roda, e no STOP `exportCombined(prerollChunks:recording:)` concatena e entrega o clipe final; fallback para "recording-only" se o export falha (`CameraManager.swift:396-442`). Chunk de 1s com keyframe/s injetado (`RecordingPipeline.swift:39`).
- **Android: stub.** `ReplayBufferHostApiImpl` lança `UnsupportedOperationException`; `CameraManager.includeReplayPreroll` é ignorado com `Log.w` (`CameraManager.kt:176`). `ReplayBufferHostApi` NÃO está registrada no `MainActivity` (só Camera e Voice estão).
- **Contrato Pigeon: pronto e INALTERADO** (`pigeons/replay_buffer_api.dart`): `enableReplayBuffer(int seconds)` / `disableReplayBuffer()` / `saveReplay()` + `onReplaySaved(path, durationMs)` / `onReplayFailed(code, message?)`. Gerado nos 3 alvos.
- **Dart: pronto e INALTERADO.** `ReplayBufferController` (estados idle/buffering/saving/failed), `camera_screen.dart` já passa `includeReplayPreroll: replayArmed` no REC e chama `setWindow(bufferDuration.value)` quando o modo replay liga. Só falta o nativo Android responder.
- **Gravação linear Android: provada** (Fatia 1, ADR-0030): `VideoCapture<Recorder>` grava MP4 H.264+AAC real no `cacheDir`, Dart copia pro vault.

## 2. Design (Rota D — ver ADR-0031)

### 2.1 Ring de segmentos
- Quando `enableReplayBuffer(seconds)` é chamado (modo replay ligado + câmera visível), o `Recorder` grava **segmentos rotativos** em `cacheDir/raro_seg_<i>.mp4`, ciclando a cada **~5s** (`stop()` do `Recording` atual → `start()` do próximo). Chunk de 5s (não 1s como iOS) porque no Android cada troca tem gap; 5s amortiza o número de emendas na janela (15s→3 segmentos, 30s→6).
- Capacidade do ring = `ceil(janela / chunk) + 1` (fórmula idêntica ao iOS `ReplayRing.capacity`). Segmento evictado é apagado do disco.
- Segmentos usam **a mesma configuração** do `Recorder` da gravação principal (mesmo `QualitySelector`/formato corrente) — pré-condição do concat sem re-encode, validada no spike (SPS/PPS idênticos).
- `disableReplayBuffer()` para o ciclo e limpa os segmentos. Buffer desarma também em `onPause`/background (mesmo gate `bindIfReady` da câmera; térmica/bateria — não manter encoder ligado fora da tela).

### 2.2 REC com pré-roll (espelho do iOS)
1. REC com `includeReplayPreroll=true` → **congela o ring** (para o ciclo; retém os segmentos da janela) e marca o segmento em andamento.
2. Grava a **gravação principal** normal (fluxo Fatia 1 intocado).
3. STOP → **concat sem re-encode** (`MediaExtractor` → `MediaMuxer`, ajuste de `presentationTimeUs`): `[segmentos da janela, começando do keyframe] + [gravação principal]` → MP4 final no `cacheDir`.
4. Entrega o path via `onRecordingFinished` (fluxo existente). Dart faz vault + sidecar + thumbnail (intocado).
5. Ring volta a rodar.
- **Fallback (paridade iOS):** se o concat falhar por QUALQUER motivo, entrega **só a gravação principal** + `Log`/evento — nunca perde o clipe do usuário.

### 2.3 Tolerância a segmento ausente/corrompido
- `cacheDir` é efêmero (o SO pode evictar; memória `raro-pattern-android-thumbnail-vault-not-cachedir`). O concat DEVE pular segmento faltando/ilegível (try/catch por segmento, log) e seguir com os que restam: a **janela degrada** (pré-roll mais curto), o clipe **nunca falha**.

### 2.4 saveReplay() standalone
- **Implementado de verdade** no host (trim/concat dos últimos N s da janela → MP4 no vault via `onReplaySaved`), reusando o mesmo `ReplayConcat` do pré-roll. **NÃO exposto na UI** (paridade: iOS também não tem botão). Decisão do dono 2026-07-18: implementar o método funcional agora, gatilho de UI é feature futura das 2 plataformas. Coberto pelo DoD com prova de que o clipe avulso sai correto no M54.

## 3. Componentes (Kotlin, `android/.../replay/`)

- `ReplaySegmentRing.kt` — ciclo/eviction de segmentos, **lógica pura** (capacidade, qual apagar, quais compõem a janela) testável sem device (rota de função pura, como a Fatia 1 Task 3).
- `ReplayConcat.kt` — `MediaExtractor`+`MediaMuxer`, ajuste de PTS, **tolerância a segmento ruim**, começar do keyframe.
- `ReplayBufferHostApiImpl.kt` — substitui o stub; orquestra ring + Recorder; emite `onReplaySaved`/`onReplayFailed`. Registrado no `MainActivity`.
- `CameraManager.kt` — `includeReplayPreroll` deixa de ser ignorado: congela ring, e no STOP dispara o concat antes de `onRecordingFinished`.

## 4. Fora de escopo

- Botão "salvar replay" na UI (§2.4). Rota C / MediaCodec (plano B do ADR-0031). Buffer durante a gravação principal. Mudança de resolução/formato do buffer (usa o formato corrente). Buffer com tela apagada.

## 5. Erros / riscos

- **Gap por emenda / no REC** — risco central; endereçado pelo spike-gate (§6) ANTES de implementar.
- **AAC priming** (estalo na emenda de áudio) — o spike inclui ESCUTAR a emenda, não só medir.
- **Bitstream divergente** entre segmentos e gravação principal — spike compara SPS/PPS via ffprobe; se divergir, concat sem re-encode é inviável (→ reavaliar).
- **cacheDir evictado** — §2.3 (degrada, não falha).
- **Térmica** (encoder sempre ligado) — desarmar fora da tela; `PowerManager` thermal listener é otimização futura, não desta fatia.

## 6. Validação (DoD)

1. **SPIKE-GATE BLOQUEANTE (1º passo, antes de bridge/UI)** — no M54, os 4 critérios do ADR-0031: (a) gap por emenda ≤ ~150ms; (b) gap no REC ≤ ~150ms; (c) SPS/PPS + codec params idênticos (ffprobe); (d) concat de 3+ segmentos reproduzível + emenda de áudio ouvida sem estalo. Reprovou → PARA (não empilha fix).
2. Implementação task-a-task com gate entre cada (analyze + testes Dart + inspeção anti-drift), como nas Fatias 1-4.
3. **Prova no M54 (gate §10):** (a) pré-roll-no-REC: buffer 15s armado → esperar >15s → REC ~5s → STOP → `ffprobe` do MP4 final: duração ≈ 15+5s (±1 chunk), A/V contínuos; reproduz na galeria; áudio audível na emenda. (b) `saveReplay()` (§2.4, sem botão — disparado via harness/debug): `ffprobe` do clipe avulso ≈ janela, A/V contínuos.
4. `ReplaySegmentRing` com testes de função pura (capacidade, eviction, janela).
5. Suíte Dart completa + analyze verdes (Dart não regride — nada muda em Dart). Build iOS compila (não tocado).
6. Auditoria 3-lentes antes do PR. ADR-0031 mergeado.
