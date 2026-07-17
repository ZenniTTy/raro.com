# ADR-0030 — Gravação linear Android via CameraX VideoCapture (Recorder)

- Status: Aceito
- Data: 2026-07-17
- Decisor: dono do produto (Eduardo)

## Contexto

No Android a gravação de vídeo é stub proposital (`CameraHostApiImpl.startRecording`/`stopRecording` lançam "not implemented until Bloco 3.1"). No teste do preview APK num Galaxy M54, REC exibia "Falha ao gravar". A Fatia 1 do pacote pré-APK (2026-07-17) implementa a gravação real; ela também é pré-requisito do comando de voz "raro gravar" da Fatia 3 — sem gravação, o comando não tem o que executar.

O Blueprint (linha 55) fixa o encoding Android como `MediaCodec` + `MediaMuxer` para "encoding + buffer". Essa escolha é a correta para o **replay buffer** (buffer circular, acesso a frames em tempo real — memória `raro-pattern-android-mediacodec-buffer-management`), mas é overkill para uma gravação linear simples.

O iOS grava `.mp4` real via `AVAssetWriter` (ADR-0018 → ADR-0020). O vault, o sidecar JSON atômico e o thumbnail são responsabilidade do Dart (`VaultService`/`recordingVaultSink`), cross-platform — o lado nativo só produz o arquivo e devolve o path via `onRecordingFinished`.

## Opções consideradas

1. **CameraX `VideoCapture<Recorder>`** (`androidx.camera:camera-video`)
   - Prós: mesma família CameraX já em uso (`camera-core/camera2/lifecycle/view:1.6.1`); faz o mux de MP4 internamente; áudio via `withAudioEnabled()`; negociação de formato via `QualitySelector` com fallback ordenado; mínimo de código e estado. Coexiste com o `Preview` no mesmo `bindToLifecycle`.
   - Contras: não dá acesso a `CMSampleBuffer`/frames em tempo real — não serve para o replay buffer; é artefato Maven novo (`camera-video`), ainda ausente do `build.gradle.kts`.
2. **`MediaCodec` + `MediaMuxer`** (o que o Blueprint fixa)
   - Prós: controle total de codec/container/buffer; é o caminho obrigatório do replay buffer.
   - Contras: muito mais código e estado (encoder, muxer, gestão de PTS, sincronização A/V) para o caso simples de gravação linear.
3. **Status quo (stub)** — não atende a fatia.

## Decisão

**Opção 1 — CameraX `VideoCapture<Recorder>`** para a **gravação linear**. Adiciona `androidx.camera:camera-video:1.6.1` (mesma família/versão dos artefatos presentes). `MediaCodec` + `MediaMuxer` fica **RESERVADO ao replay buffer / pré-roll** (fatia futura), onde o buffer circular é obrigatório.

- `Recorder.Builder().setQualitySelector(QualitySelector.fromOrderedList(...))` derivado do formato corrente, com fallback logado (sem fallback silencioso — gate §10).
- `prepareRecording(context, FileOutputOptions).withAudioEnabled().start(mainExecutor, consumer)`.
- Grava em arquivo temp `raro_<sessionId>.mp4` no `cacheDir`; o Dart copia pro vault. `includeReplayPreroll` é ignorado com `Log.w` explícito nesta fatia.
- Contrato Pigeon **inalterado** (`startRecording`/`stopRecording`/`onRecordingStarted`/`onRecordingFinished`/`onRecordingFailed` já existem).

## Consequências

- **Atualiza o Blueprint (linha 55):** encoding Android passa a distinguir gravação linear (CameraX Recorder) de replay/pré-roll buffer (MediaCodec + MediaMuxer, fatia futura).
- Paridade de gravação linear com o iOS (ambos produzem `.mp4`; vault/sidecar/thumbnail compartilhados no Dart).
- Dependência nova `camera-video:1.6.1` — coberta por este ADR.
- Prova objetiva de formato exigida (gate §10): `ffprobe` no clipe puxado do device comprovando vídeo + áudio.

## Referências

- Spec: `docs/superpowers/specs/2026-07-17-gravacao-android-videocapture-design.md`
- Plan: `docs/superpowers/plans/2026-07-17-gravacao-android-videocapture.md`
- ADR-0018 / ADR-0020 (estratégia de gravação MP4 no iOS)
- Memória `raro-pattern-android-mediacodec-buffer-management` (por que o replay exige MediaCodec)
