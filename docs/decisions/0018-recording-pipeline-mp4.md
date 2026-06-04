# 0018 — Recording pipeline (AVCaptureMovieFileOutput)

- **Data:** 2026-06-03
- **Status:** Accepted
- **Supersedes:** ADR-0015 item 7 ("Sem gravação") — gravação agora está em escopo.
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sprint 2 G1 (gravação real de vídeo em P05). Cruza o boundary explícito de ADR-0015 e precede qualquer mudança no contrato Pigeon (`apps/mobile/pigeons/camera_api.dart`).

## Contexto

O Sprint 2 G1 exige gravação real de vídeo na tela de câmera (P05). Até aqui a camada nativa iOS adiciona **zero** outputs de captura — o preview é puramente `AVCaptureVideoPreviewLayer` (ADR-0015, addendum sobre PlatformView). Para gravar, o contrato Pigeon precisa ganhar `startRecording`/`stopRecording`.

ADR-0015 item 7 fechou explicitamente o escopo da bridge de câmera em "**Sem gravação** nesta ADR — boundary explícito com replay_buffer." Esta ADR cruza esse boundary e portanto o substitui no que tange ao item 7. O `replay_buffer` (gravação retroativa do buffer circular) permanece em ADR-0003 e fora do escopo aqui.

A sessão de captura usa `sessionPreset = .inputPriority` (mandatório para o mapping de zoom dual-wide do iPhone 12 — ADR-0015 addendum B + memória `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`). Qualquer output de gravação precisa coexistir com essa configuração de sessão sem sobrescrever `device.activeFormat`.

O Blueprint e o plano do Sprint 2 chamam o artefato coloquialmente de "MP4". O container real produzido pela API escolhida **não é `.mp4`** — esta ADR registra essa discrepância de forma honesta (ver Decisão item 3).

## Opções consideradas

1. **`AVCaptureMovieFileOutput`** (output file-based)
   - Prós: config mínima, API estável, lida com finalização de arquivo, suporta HEVC e H.264 via `availableVideoCodecTypes` + `setOutputSettings(_:for:)`. Adequado para "gravar um clipe contínuo do preview".
   - Contras: emite container QuickTime `.mov` (não há seletor de container nesta classe); não vende `CMSampleBuffer` (não serve para o replay buffer); não garante dimensões exatas de `activeFormat` para todos os formats (notadamente 4K60).
2. **`AVAssetWriter` + `AVCaptureVideoDataOutput`**
   - Prós: acesso real-time a `CMSampleBuffer`, controle total de container (`AVFileType.mp4`), codec e dimensões; é o caminho obrigatório do replay buffer.
   - Contras: muito mais código e estado (pixel buffer pool, gestão de PTS, queue de sample buffers, sincronização de áudio/vídeo) para o caso simples de gravação contínua. Overkill para G1.
3. **Status quo (não gravar)**
   - Prós: nenhum trabalho.
   - Contras: não atende G1.

## Decisão

**Opção 1 — `AVCaptureMovieFileOutput`** para a gravação contínua de G1. `AVAssetWriter` fica **reservado** ao replay buffer (refresh de ADR-0003, Task B / S2.B), porque só o AssetWriter dá acesso real-time a `CMSampleBuffer`.

1. **Output API.** `AVCaptureMovieFileOutput` (file-based, config mínima, suporta HEVC+H264). `AVAssetWriter` não é usado em G1.

2. **Codec.** Default **HEVC** (`AVVideoCodecType.hevc`); fallback **H.264** (`AVVideoCodecType.h264`) quando `output.availableVideoCodecTypes` não inclui HEVC. O codec é aplicado via `setOutputSettings([AVVideoCodecKey: codec], for: videoConnection)` **depois** do output ser adicionado à sessão e da `videoConnection` existir.

3. **Container — `.mov`, não `.mp4`.** `AVCaptureMovieFileOutput` emite container **QuickTime `.mov`** (verificado contra docs Apple + Apple Developer Forums: "AVCaptureMovieFileOutput writes QuickTime Movie Files (.mov)"); não existe seletor de container nessa classe. Os arquivos são gravados como `<id>.mov`. **Honestidade explícita:** o Blueprint/plano dizem coloquialmente "MP4"; o artefato real é `.mov` (vídeo H.264/HEVC dentro de QuickTime). O `video_player` (iOS AVPlayer) e o `share_plus` lidam com `.mov` nativamente, então isso é aceitável para galeria/preview/share. Se um `.mp4` verdadeiro for exigido no futuro, requer `AVAssetWriter` com `AVFileType.mp4` ou transcode via `AVAssetExportSession` — fora de escopo aqui (registrado em Consequências).

4. **Shape do contrato — correção crítica do Sprint 2 MD.** O contrato é:
   - `startRecording(RecordingOptions) -> String sessionId` (retorno síncrono de um id)
   - `stopRecording() -> void`
   - O path do arquivo salvo é entregue **assíncrono** via novo callback `@FlutterApi`: `onRecordingFinished(String path, int durationMs)` (+ `onRecordingFailed(CameraErrorCode code, String? message)`).

   **Por quê:** `AVCaptureMovieFileOutput` finaliza o arquivo no delegate `fileOutput(_:didFinishRecordingTo:from:error:)`, **não** sincronamente. O `stopRecording()` retornando o path de forma síncrona — como descreve o Sprint 2 MD — está **errado** para `MovieFileOutput`: o arquivo ainda não está finalizado quando `stopRecording()` retorna. Esta é a decisão de design mais importante desta ADR e a razão de o path vir por callback assíncrono.

5. **Enum `Codec` em `raro_shared`.** Novo enum `Codec` (`h264`, `h265`) em `raro_shared` (tipo cross-stack compartilhado). Reusar os enums `Resolution`/`Fps` já existentes em `raro_shared`. A classe Pigeon `RecordingOptions` carrega o codec como **String** plana (Pigeon não importa `raro_shared`) = `Codec.label` (`"h264"`/`"h265"`).

## Consequências

- **Positivas:**
  - Config mínima entrega G1 sem o estado e a complexidade do AssetWriter.
  - Codec adaptativo (HEVC com fallback H.264) sem hardcode de formato.
  - `.mov` é consumível por `video_player` e `share_plus` sem transcode.
  - Boundary limpo com o replay buffer: AssetWriter continua reservado para ADR-0003 / Task B.

- **Negativas / riscos conhecidos:**
  - **`MovieFileOutput` não vende sample buffers.** O replay buffer (Task B) precisa de um **segundo** output (`AVCaptureVideoDataOutput` + `AVAssetWriter`) na mesma sessão `.inputPriority`. A coexistência de `MovieFileOutput` + `VideoDataOutput` numa única sessão **precisa ser validada na Task B** (flag de risco).
  - **Dimensões do arquivo gravado ≠ `activeFormat`.** Sob `.inputPriority`, `device.activeFormat` governa o QoS dos outputs, mas `MovieFileOutput` **não garante** que as dimensões do arquivo gravado sejam exatamente iguais ao `activeFormat` para todos os formats (notadamente 4K60). Se gravação com match exato de dimensões for exigida no futuro, trocar para `AVAssetWriter` (flag de risco).
  - **Artefato é `.mov`, não `.mp4`.** Se um `.mp4` verdadeiro for requisito, exige AssetWriter (`AVFileType.mp4`) ou transcode (`AVAssetExportSession`) — não coberto aqui.

- **Como reverter:** novo ADR substituindo, com revert das mudanças no contrato Pigeon (`startRecording`/`stopRecording`/`onRecordingFinished`/`onRecordingFailed`/`RecordingOptions`) e do enum `Codec` em `raro_shared`. O item 7 de ADR-0015 voltaria a vigorar.

## Referências

- ADR-0015 (boundary cruzado — item 7 "Sem gravação"): [0015-camera-native-bridge-strategy.md](0015-camera-native-bridge-strategy.md)
- ADR-0013 (mecanismo Pigeon / anti-drift): [0013-pigeon-theme-tailor-and-anti-drift-gates.md](0013-pigeon-theme-tailor-and-anti-drift-gates.md)
- ADR-0003 (replay buffer / AVCaptureSession compartilhada): [0003-replay-buffer-native.md](0003-replay-buffer-native.md)
- Apple docs: `AVCaptureMovieFileOutput.availableVideoCodecTypes`, `setOutputSettings(_:for:)`, `AVVideoCodecType`
- Apple Developer Forums: "AVCaptureMovieFileOutput writes QuickTime Movie Files (.mov)"
- Memória `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping` (sessionPreset `.inputPriority`)
