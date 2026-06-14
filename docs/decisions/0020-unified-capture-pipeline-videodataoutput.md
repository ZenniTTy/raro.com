# 0020 — Pipeline de captura unificado (AVCaptureVideoDataOutput + AVAssetWriter)

- **Data:** 2026-06-04
- **Status:** Accepted
- **Supersedes:** ADR-0018 (Recording pipeline / AVCaptureMovieFileOutput) — a gravação contínua G1 migra do `AVCaptureMovieFileOutput` para o pipeline unificado descrito aqui.
- **Relaciona:** ADR-0003 (replay buffer — reescrito em conjunto), ADR-0015 (bridge strategy), ADR-0016 (harness E2E híbrido).
- **Decisores:** Eduardo Rodrigues
- **Contexto:** Sprint 2 Task B (S2.B — replay buffer). Pré-flight da S2.B (auditoria multi-agente 2026-06-04) confirmou que a estratégia implícita no ADR-0018 + plano S2.B é tecnicamente inviável.

## Contexto

O ADR-0018 escolheu `AVCaptureMovieFileOutput` para a gravação contínua de G1 (entregue na S2.A, sessões 0016/0017, validado no iPhone 12) e **reservou** `AVAssetWriter` ao replay buffer (Task B / S2.B), com a expectativa de que os dois outputs coexistissem na mesma `AVCaptureSession` `.inputPriority`. A própria ADR-0018 (Consequências) marcou essa coexistência como **flag de risco a validar na Task B**.

A auditoria de pré-flight da S2.B validou esse risco contra fontes de primeira mão (Apple Developer Forums, docs Apple, código da React Native Vision Camera) e o veredito é: **a coexistência não é suportada**.

Fatos confirmados:

1. **`AVCaptureMovieFileOutput` + `AVCaptureVideoDataOutput` não convivem.** Em iOS 15+ (e ainda em 2026), os dois caminhos de vídeo numa única `AVCaptureSession` são mutuamente exclusivos: apenas um entrega frames de forma confiável. `canAddOutput(_:)` pode retornar `true` para ambos e as connections se formam — mas o conflito é de **entrega na connection `.video` em runtime**, não de validação na adição. Isso é arquitetural, não um bug de versão.

2. **Prova de existência em produção.** A `react-native-vision-camera` (maior lib AVFoundation de terceiros) implementa gravação + frame processing simultâneos com um delegate **customizado** de `AVCaptureVideoDataOutput` + `AVAssetWriter`, declarando explicitamente o motivo: *"you cannot use the AVCaptureMovieFileOutput and an AVCaptureVideoDataOutput delegate at the same time"*. Faz o mesmo para áudio (`AVCaptureAudioDataOutput`).

3. **O `MovieFileOutput` do RARO já é permanente.** `CameraManager.startSession` chama `recordingPipeline.attach(to:)` **incondicionalmente** dentro do `begin/commitConfiguration` — o `AVCaptureMovieFileOutput` fica anexado à sessão durante todo o ciclo de vida, não só durante a gravação. Logo, adicionar um `AVCaptureVideoDataOutput` para o replay faria os dois coexistirem **permanentemente**, com alta probabilidade de degradar a gravação G1 já validada em device.

4. **A recomendação oficial da Apple** quando se precisa de gravação **E** acesso a frames (= o caso do RARO: gravação G1 + replay buffer S2.B) é escolher **um** caminho: `AVCaptureVideoDataOutput` + `AVAssetWriter` para tudo. *"If you need to modify your frames prior to encoding, you have to use AVAssetWriter."* O próprio ADR-0018 (opção 2) já reconhecia o AssetWriter como "o caminho obrigatório do replay buffer".

5. **`AVCaptureMultiCamSession` não é solução.** Overkill para single-cam (Apple: a `AVCaptureSession` padrão é preferida para captura single-cam), não permite `MovieFileOutput` em paralelo, e cobra caro em energia/térmico/memória no iPhone 12. Alinhado com a memória `raro-pattern-ios-avcapture-multicam-not-needed`.

## Opções consideradas

1. **Manter `MovieFileOutput` (G1) e adicionar `VideoDataOutput` (replay) na mesma sessão** — o que o ADR-0018 + plano S2.B implicavam.
   - Prós: não refatora o `RecordingPipeline` já validado.
   - Contras: **não suportado pela Apple**; degrada/para a gravação G1 em runtime; `canAddOutput` dá falso positivo; áudio também colide (`AudioDataOutput` vs roteamento do `MovieFileOutput`). Inviável.

2. **Pipeline unificado: um único `AVCaptureVideoDataOutput` (+ `AVCaptureAudioDataOutput`) alimentando `AVAssetWriter`, servindo gravação contínua E replay buffer no mesmo callback `captureOutput(_:didOutput:from:)`.**
   - Prós: caminho oficial Apple; um só caminho de vídeo (sem conflito de connection); container `.mp4` nativo (`AVFileType.mp4`); reusa o mesmo stream de buffers para clipe contínuo e ring buffer; é o padrão da Vision Camera.
   - Contras: refatora o `RecordingPipeline.swift` (código device-validated); mais estado (PTS, `startSession(atSourceTime:)`, áudio sync, finalize assíncrono); exige re-validação em device de gravação, preview, foco, lens switch.

3. **`AVCaptureMultiCamSession`.**
   - Prós: nenhum relevante aqui.
   - Contras: overkill, contraindicado para single-cam, não resolve a coexistência com `MovieFileOutput`, custo térmico no iPhone 12.

4. **Status quo (replay fora de escopo, manter só gravação `MovieFileOutput`).**
   - Prós: nenhum trabalho.
   - Contras: replay (Raro Replay) é feature core do produto (Blueprint §2.2 + 3.3); não atender é não entregar o Sprint 2.

## Decisão

**Opção 2 — pipeline de captura unificado.** A camada nativa iOS passa a usar **um único `AVCaptureVideoDataOutput`** (+ `AVCaptureAudioDataOutput`) anexado à `AVCaptureSession` `.inputPriority`, cujo delegate alimenta **`AVAssetWriter`** para:

- **(a) gravação contínua (G1)** — `AVAssetWriterInput` de vídeo + áudio, escrevendo o clipe enquanto o usuário grava; e
- **(b) replay buffer (G2)** — ring buffer **encoded** dos últimos N segundos (15s/30s), drenado para um `AVAssetWriter` ao "Salvar replay".

Pontos da decisão:

1. **Output único de vídeo.** `AVCaptureMovieFileOutput` é **aposentado** do caminho de vídeo. O `RecordingPipeline.swift` é refatorado para alimentar o `AVAssetWriter` a partir do `captureOutput` do `VideoDataOutput`.

2. **Container `.mp4` real.** O `AVAssetWriter` é criado com `AVFileType.mp4`, fechando o drift `.mov`/`.mp4` que o ADR-0018 documentou. O `vault_service` e a galeria, que hoje filtram/leem `.mov`, precisam migrar para `.mp4` no mesmo PR de implementação (ver Consequências / breaking change).

3. **Áudio via `AVCaptureAudioDataOutput`.** O input de áudio continua na sessão, mas o caminho de gravação consome áudio via `AudioDataOutput` → `AVAssetWriterInput` de áudio no mesmo writer (não via `MovieFileOutput`). Mantém o fix de "gravação sem áudio = `.mov` mudo" (memória `raro-pattern-flutter-async-native-state-needs-notifier`) sob a nova arquitetura. Cuidar do priming AAC (~48ms) e do sync de PTS áudio/vídeo.

4. **Ring buffer encoded, não raw.** O buffer de replay mantém segmentos **já encodados** (estratégia fragmented MP4 via `AVAssetWriterDelegate.didOutputSegmentData` em deque circular, OU ring de `CMSampleBuffer` drenado com `startSession(atSourceTime:)` — decisão final detalhada no ADR-0003 reescrito). **Não** reter array de `CMSampleBuffer` crus (anti-padrão de memória — ver ADR-0003).

5. **Queue dedicada para o delegate.** O `setSampleBufferDelegate(_:queue:)` do `VideoDataOutput` usa uma **dispatch queue dedicada**, NÃO a `sessionQueue` serial compartilhada com `focusAtAsync` — para não regredir o hot path de tap-to-focus (gate CLAUDE.md §10). Anexar o `CMSampleBuffer` direto via `append(sampleBuffer:)`, **sem** `AVAssetWriterInputPixelBufferAdaptor` nem `CVPixelBufferPool` no passthrough captura→writer.

6. **`startSession(atSourceTime:)` ancorado no PTS.** O `AVAssetWriter` ancora no `CMSampleBufferGetPresentationTimeStamp` do primeiro buffer recebido. Reconfiguração de sessão (lens switch físico, `setFormat`) finaliza o segmento atual e reabre o writer com as novas dimensões — tratada como evento que limpa/reancora o buffer de replay.

7. **Save assíncrono.** `finishWriting(completionHandler:)` do `AVAssetWriter` é assíncrono. Todo path salvo (gravação E replay) é entregue por **callback `@FlutterApi`** (`onRecordingFinished` para gravação — já existe; `onReplaySaved` para replay — ver ADR-0003), nunca retorno síncrono. Mantém a decisão item 4 do ADR-0018.

## Consequências

- **Positivas:**
  - Caminho oficial Apple — sem o conflito de coexistência que mataria a gravação.
  - Um único caminho de vídeo serve gravação E replay (menos estado de sessão, sem dois outputs concorrentes).
  - Container `.mp4` real, fechando o drift `.mov`/`.mp4` do ADR-0018.
  - Arquitetura validada em produção pela Vision Camera (espelhável).

- **Negativas / riscos conhecidos:**
  - **Breaking change interno:** refatora `RecordingPipeline.swift` (código device-validated na S2.A). A gravação G1 precisa ser **re-validada em iPhone 12 físico** após a migração — não pode ser declarada pronta por XCTest/Simulator (memória `feedback_device_debug_use_real_logs_not_assumptions` + gate §10).
  - **Breaking change de artefato:** arquivos passam de `.mov` para `.mp4`. `vault_service.dart` (lê `.mov`), `RecordingPipeline.makeOutputURL` (`.mov`), e qualquer filtro de extensão precisam migrar juntos. Vídeos `.mov` gravados antes desta build: decidir migração retroativa (provável: sem migração, vault novo — baixo impacto, alinhado com a decisão do thumbnail na 0017) e documentar no PR.
  - **Re-validação em device das features que compartilham a sessão:** preview ao vivo (`previewLayer.session` é o MESMO objeto), tap-to-focus (queue), lens switch 0.5×/1× (caminho físico reconfigura connection), background/foreground observers. Cada uma re-validada antes de "pronto".
  - **Memória / térmico iPhone 12 (A14, 4GB, jetsam ~2GB hard):** buffer encoded (~30-37MB para 30s@1080p) em vez de raw; gate de `ProcessInfo.thermalState` degradando fps/resolução sob `.serious`/`.critical`. Dimensionamento detalhado no ADR-0003.
  - **Custo de migração medido em fontes externas:** RAM ~58→187MB e CPU 3-5%→7-12% ao trocar `MovieFileOutput` por `VideoDataOutput`+`AssetWriter` (números de forum thread — validar em device real).

- **Como reverter:** novo ADR substituindo. Reverter exige restaurar o `RecordingPipeline` baseado em `MovieFileOutput` (commit da S2.A) e o artefato `.mov`. O ADR-0018 voltaria a vigorar para o caminho de gravação. O replay buffer (ADR-0003) ficaria sem caminho técnico viável — por isso a reversão só faz sentido se o replay sair de escopo.

## Referências

- ADR-0018 (superseded por este): [0018-recording-pipeline-mp4.md](0018-recording-pipeline-mp4.md)
- ADR-0003 (replay buffer — reescrito em conjunto): [0003-replay-buffer-native.md](0003-replay-buffer-native.md)
- ADR-0015 (bridge strategy): [0015-camera-native-bridge-strategy.md](0015-camera-native-bridge-strategy.md)
- ADR-0016 (harness E2E híbrido — gate de validação em device): [0016-e2e-harness-hybrid.md](0016-e2e-harness-hybrid.md)
- Apple docs: `AVCaptureVideoDataOutput`, `AVAssetWriter`, `AVAssetWriter.startSession(atSourceTime:)`, `AVAssetWriterDelegate`, `AVCaptureMovieFileOutput`, `AVCaptureMultiCamSession`
- Apple Developer Forums: thread/14323 (mutually exclusive outputs), thread/679250, thread/73800 (MovieFileOutput vs AssetWriter), TN2445 (frame drops), thread/688973 (jetsam per-process iPhone)
- React Native Vision Camera (prova de existência): github.com/mrousavy/react-native-vision-camera (FRAME_PROCESSORS.mdx, issue #1837)
- Memórias: `raro-pattern-ios-cvpixelbufferpool`, `raro-pattern-ios-avcapture-multicam-not-needed`, `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`, `raro-pattern-ios-platformview-camera-preview-black`, `raro-pattern-flutter-async-native-state-needs-notifier`
- Auditoria de pré-flight S2.B: sessão 0018 (este documento)
