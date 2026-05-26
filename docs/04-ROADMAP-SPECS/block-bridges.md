# Bloco Native Bridges — specs 007 a 009

> 3 specs de Large 🔴 risk. Compõem o core técnico do produto: captura de vídeo, replay buffer e voice wake-word. Cada bridge tem implementação em Swift (iOS/AVFoundation) e Kotlin (Android/CameraX/SpeechRecognizer). **Contract test em ambas plataformas é obrigatório.**

> **Ordem é sequencial, não paralela.** Camera estabelece o pipeline de `AVCaptureSession`/`CameraX` que Replay Buffer estende. Voice depende de pipeline de áudio que se beneficia da estrutura de Camera + Replay.

## spec-007 — camera-native-bridge

| Campo | Valor |
|---|---|
| **Sizing** | Large 🔴 |
| **Dependências** | spec-001 (LensDescriptor, CameraCaptureResult, VideoCodec, CameraError em shared), spec-002 (Firebase analytics), spec-004 (theme tokens para HUD) |
| **Bloqueia** | spec-008 (replay-buffer), spec-009 (voice), spec-010 (volume), spec-011 (lock-mode), spec-015 (gallery) |
| **Branch sugerido** | `feat/camera-native-bridge` |
| **Telas afetadas** | P05 (Câmera) — HUD básico com viewport, REC button, lens toggle |
| **ADRs envolvidos** | 0002 (native bridge custom), novo 0016 (contrato JSON `com.rarocamera/camera`) |

### Problem

Plugin oficial `camera` não suporta alternância física entre lentes 0.5× e 1× (issues `flutter#91247` e `flutter#173406`). Implementação **100% nativa** via Method Channel `com.rarocamera/camera`. Esta spec entrega o **mínimo viável** da câmera: discovery de lentes, captura sem buffer (replay vem em spec-008), HUD básico.

### Contract JSON (Method Channel)

Vai virar `apps/mobile/lib/core/native_bridges/camera_contract.md` + `camera_method_channel.dart`. Métodos:

| Método | Args | Retorno |
|---|---|---|
| `discoverLenses` | — | `List<LensDescriptor>` |
| `setLens` | `{lens: '0.5x'|'1x'}` | `void` |
| `setResolution` | `{resolution: '720p'|'1080p'|'4K'|'4K60'}` | `void` |
| `setFps` | `{fps: 30|60}` | `void` |
| `startCapture` | — | `{recordingId: String}` |
| `stopCapture` | — | `CameraCaptureResult` |
| `tapToFocus` | `{x: double, y: double}` | `void` |

Eventos (EventChannel):
- `onFocusChanged: {x, y}` — após tap, native confirma novo ponto
- `onError: CameraError` — propaga `CameraError` (sealed em shared)

### Atomic micro-sprints

#### 7.1 — Contract JSON publicado + ADR 0016

**Files:**
- `docs/decisions/0016-camera-bridge-contract.md` — define JSON shape canônico, error codes, threading model
- `apps/mobile/lib/core/native_bridges/camera_contract.md` — versão human-readable do contrato
- `docs/10-CHANGELOG.md` (entry)

**Verification:**
- ADR 0016 referencia tipos de shared (LensDescriptor, CameraCaptureResult, CameraError)
- Sem invenção: cada method/event aparece em [docs/07-NATIVE-BRIDGES.md](../07-NATIVE-BRIDGES.md)
- `docs-lint` zero

**Commit:** `docs(blueprint): adr 0016 + contrato camera method channel — spec-007 µ-sprint 7.1`

#### 7.2 — Dart side: `CameraMethodChannel` wrapper

**Files:**
- `apps/mobile/lib/core/native_bridges/camera_method_channel.dart` — abstração sobre `MethodChannel('com.rarocamera/camera')`
- `apps/mobile/lib/core/native_bridges/camera_event_channel.dart` — abstração sobre `EventChannel`
- `apps/mobile/test/core/native_bridges/camera_method_channel_test.dart` — usa `TestDefaultBinaryMessengerBinding`

**Verification:**
- `flutter analyze` zero
- `flutter test` verde (mocking platform channel)
- Métodos retornam tipos canônicos de shared, não Map<String, dynamic>

**Commit:** `feat(bridge): dart wrapper para com.rarocamera/camera method channel — spec-007 µ-sprint 7.2`

#### 7.3 — iOS: `CameraManager.swift` com AVFoundation

**Files:**
- `apps/mobile/ios/Runner/Native/CameraManager.swift`
- `apps/mobile/ios/Runner/Native/CameraMethodHandler.swift` — registra Method Channel
- `apps/mobile/ios/Runner/AppDelegate.swift` — registra handler no plugin registry
- `apps/mobile/ios/RunnerTests/CameraManagerTests.swift` — XCTest cobrindo discovery de lentes

**Stack iOS:**
- `AVCaptureDevice.DiscoverySession` com `builtInUltraWideCamera` + `builtInWideAngleCamera`
- `AVCaptureSession` + `AVAssetWriter` para pipeline
- Privacy: `NSCameraUsageDescription` em `Info.plist`

**Verification:**
- `xcodebuild test -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 15 Pro'` passa
- SwiftLint zero
- `flutter build ios --no-codesign --simulator` compila
- Discovery em iPhone real expõe ambas lentes (test manual em device físico)

**Commit:** `feat(bridge): ios camera manager com avfoundation — spec-007 µ-sprint 7.3`

#### 7.4 — Android: `CameraManager.kt` com CameraX

**Files:**
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/CameraManager.kt`
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/CameraMethodHandler.kt`
- `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt` — registra handler
- `apps/mobile/android/app/src/main/AndroidManifest.xml` — permission CAMERA
- `apps/mobile/android/app/src/test/kotlin/com/rarocamera/CameraManagerTest.kt`

**Stack Android:**
- `CameraSelector.Builder().addCameraFilter()` filtrando `LENS_INFO_AVAILABLE_FOCAL_LENGTHS`
- `MediaCodec` + `MediaMuxer` para encoding

**Verification:**
- `./gradlew test` passa
- ktlint zero
- `flutter build apk --debug` compila
- Discovery em Pixel real expõe ambas lentes

**Commit:** `feat(bridge): android camera manager com camerax — spec-007 µ-sprint 7.4`

#### 7.5 — HUD básico da P05 (Dart side)

**Files:**
- `apps/mobile/lib/features/camera/presentation/camera_screen.dart`
- `apps/mobile/lib/features/camera/presentation/widgets/camera_viewport.dart`
- `apps/mobile/lib/features/camera/presentation/widgets/record_button.dart`
- `apps/mobile/lib/features/camera/presentation/widgets/lens_toggle.dart`
- `apps/mobile/lib/features/camera/application/camera_controller.dart` — `@riverpod` provider
- `apps/mobile/lib/features/camera/application/camera_controller.g.dart` (gerado)
- `apps/mobile/test/features/camera/camera_screen_widget_test.dart`
- `apps/mobile/test/features/camera/goldens/camera_screen_idle.png` (golden)

**Verification:**
- `flutter analyze` zero
- `flutter test --update-goldens` regenera baseline
- `design-fidelity-checker` invocado: tela bate com P05 do protótipo (cores, gradient line bottom, rec button, lens pills, viewport ratio)
- `run-riverpod-codegen` hook sinaliza, codegen rodado, `.g.dart` em diff

**Commit:** `feat(camera): hud básico p05 com viewport + rec + lens toggle — spec-007 µ-sprint 7.5`

#### 7.6 — Integration test em device físico

**Files:**
- `apps/mobile/integration_test/camera_flow_test.dart`

**Test cenário:**
- App boota → P05 visível → discovery retorna ≥1 lens → toque em REC inicia captura → toque novamente para → arquivo .mp4 existe no path retornado

**Verification:**
- `flutter test integration_test/camera_flow_test.dart` em iPhone físico passa
- `flutter test integration_test/camera_flow_test.dart` em Pixel físico passa
- Manual: ver vídeo gravado no Photos app

**Commit:** `test(camera): integration test discovery+capture em device físico — spec-007 µ-sprint 7.6`

#### 7.7 — Validator + design-fidelity + session log

**Files:**
- `docs/sessions/<NNNN>-camera-native-bridge.md`
- `docs/10-CHANGELOG.md` (entry final da spec)

**Verification:**
- `validator` agent confirma todas observable goals da spec
- `design-fidelity-checker` aprova P05 contra protótipo
- `adr-guardian` confirma ADR 0016 mergeado
- `/verify-slice` passa

**Commit:** `docs(camera): session log + changelog spec-007 — spec-007 µ-sprint 7.7`

### Gates específicos spec-007

- `warn-adr-drift` em `Info.plist` e `AndroidManifest.xml` (mudanças de permission)
- `block-env` protege qualquer arquivo de signing
- Contract test em iOS + Android obrigatório no `/verify-slice`
- `flutter-perf-auditor` invocado para validar rebuild count em HUD (deve ser baixo — viewport é stateful mas HUD reage só a state changes)

---

## spec-008 — replay-buffer

| Campo | Valor |
|---|---|
| **Sizing** | Large 🔴 |
| **Dependências** | spec-007 (pipeline AVCaptureSession/CameraX já existe), spec-001 (ReplayBufferState, BridgeError) |
| **Bloqueia** | spec-009 (voice — pode disparar replay), spec-013 (paywall — gate de salvar) |
| **Branch sugerido** | `feat/replay-buffer` |
| **Telas afetadas** | P05 (adiciona buffer pill + buffer bar + duration toggle) |
| **ADRs envolvidos** | 0003 (replay buffer nativo), novo 0017 (contrato `com.rarocamera/replay_buffer`) |

### Problem

Feature core do produto: buffer circular em RAM dos últimos 15 ou 30s. Ao receber "salvar", prepend do buffer ao stream contínuo. Sem plugin Flutter pronto — 100% nativo. Consumo estimado: 15s/1080p ≈ 70MB, 30s/4K ≈ 560MB → pool reutilizável obrigatório para evitar GC pressure.

### Contract JSON (Method Channel)

| Método | Args | Retorno |
|---|---|---|
| `setBufferDuration` | `{seconds: 15|30}` | `void` |
| `startBuffering` | — | `void` |
| `stopBuffering` | — | `void` |
| `saveWithPreroll` | — | `{recordingId, filePath, prerollSeconds}` |

Eventos:
- `onBufferState: ReplayBufferState`
- `onFrameDropped: {timestamp}` — sinaliza pressure
- `onError: BridgeError`

### Atomic micro-sprints

#### 8.1 — ADR 0017 + contract md

`docs/decisions/0017-replay-buffer-contract.md` + `replay_buffer_contract.md`. **Commit:** `docs(blueprint): adr 0017 contrato replay buffer — spec-008 µ-sprint 8.1`

#### 8.2 — Dart side wrapper

`replay_buffer_method_channel.dart` + `replay_buffer_event_channel.dart` + provider Riverpod + tests. **Commit:** `feat(bridge): dart wrapper replay_buffer — spec-008 µ-sprint 8.2`

#### 8.3 — iOS: `ReplayBufferManager.swift`

`CMSampleBuffer` array circular + `AVAssetWriter` para concat. Pool reutilizável de buffers para minimizar alloc. XCTest cobrindo overflow do buffer. **Commit:** `feat(bridge): ios replay buffer com cmsamplebuffer pool — spec-008 µ-sprint 8.3`

#### 8.4 — Android: `ReplayBufferManager.kt`

`MediaCodec` com H.264, `ByteBuffer` circular + `MediaMuxer` para concat. **Commit:** `feat(bridge): android replay buffer com mediacodec pool — spec-008 µ-sprint 8.4`

#### 8.5 — HUD updates na P05

Buffer pill "Raro Replay 15s" top-right com dot pulsante. Buffer bar fill animation 15s loop. Toggle 15↔30s. Goldens regerados. **Commit:** `feat(camera): hud buffer pill + buffer bar + duration toggle — spec-008 µ-sprint 8.5`

#### 8.6 — Stress test de RAM

Integration test que grava 30s/4K em device real, observa heap via Flutter DevTools, valida que não excede 600MB. **Commit:** `test(replay): stress test ram 30s/4K em device físico — spec-008 µ-sprint 8.6`

#### 8.7 — Validator + perf-auditor + session log

`flutter-perf-auditor` invocado especificamente para Replay Buffer (RAM management, frame drops). **Commit:** `docs(replay): session log + changelog spec-008 — spec-008 µ-sprint 8.7`

### Gates específicos spec-008

- `flutter-perf-auditor` obrigatório (RAM management)
- Contract test em ambas plataformas obrigatório
- Stress test em device físico (não simulator) obrigatório
- Frame drop count em telemetria via Firebase (sinaliza problema em produção)

---

## spec-009 — voice-wake-word

| Campo | Valor |
|---|---|
| **Sizing** | Large 🔴 |
| **Dependências** | spec-007 (pipeline de áudio já existe), spec-001 (VoiceDetection, VoiceListeningState, VoiceError) |
| **Bloqueia** | spec-010 (volume — mode toggle) |
| **Branch sugerido** | `feat/voice-wake-word` |
| **Telas afetadas** | P05 (adiciona hint "DIGA 'RARO' PARA GRAVAR" central), P02 (onboarding já cita) |
| **ADRs envolvidos** | 0009 (wake word "Raro"), novo 0018 (contrato `com.rarocamera/voice`) |

### Problem

Detecção on-device do wake word `"Raro"` para iniciar/encerrar gravação hands-free. iOS: `SFSpeechRecognizer`. Android: `SpeechRecognizer` com `EXTRA_PREFER_OFFLINE`. iOS tem limite de 1 minuto por sessão → restart automático. **Privacidade: áudio nunca sai do device.**

### Contract JSON

| Método | Args | Retorno |
|---|---|---|
| `startListening` | — | `void` |
| `stopListening` | — | `void` |
| `setWakeWord` | `{word: 'Raro'}` | `void` |

Eventos:
- `onWakeDetected: VoiceDetection { confidence, timestamp }`
- `onSessionRestart: {reason}` — iOS limit
- `onError: VoiceError`

### Atomic micro-sprints

#### 9.1 — ADR 0018 + contract + Privacy Manifest

`docs/decisions/0018-voice-bridge-contract.md`. Inclui Privacy Manifest iOS declarando uso de speech (NSSpeechRecognitionUsageDescription, NSMicrophoneUsageDescription). **Commit:** `docs(blueprint): adr 0018 voice contract + privacy manifest — spec-009 µ-sprint 9.1`

#### 9.2 — Dart side wrapper + Riverpod

`voice_method_channel.dart` + `voice_listening_provider.dart` (`@riverpod`). **Commit:** `feat(bridge): dart wrapper voice + listening provider — spec-009 µ-sprint 9.2`

#### 9.3 — iOS: `VoiceWakeWordDetector.swift`

`SFSpeechRecognizer` configurado on-device. Timer para detectar fim de sessão e reiniciar automaticamente. Buffer de samples sliding window. **Commit:** `feat(bridge): ios voice wake word com sfspeechrecognizer on-device — spec-009 µ-sprint 9.3`

#### 9.4 — Android: `VoiceWakeWordDetector.kt`

`SpeechRecognizer` com `EXTRA_PREFER_OFFLINE` (API 31+). **Commit:** `feat(bridge): android voice wake word com speechrecognizer offline — spec-009 µ-sprint 9.4`

#### 9.5 — HUD updates + integração com record toggle

Hint central "DIGA 'RARO' PARA GRAVAR" aparece quando `VoiceListeningState == listening` e `RecordingState == idle`. Wake detectado dispara `cameraController.toggleRecord()`. **Commit:** `feat(voice): integra wake word com toggle de recording — spec-009 µ-sprint 9.5`

#### 9.6 — Test de detecção em ambiente real

Manual test em ambiente silencioso + ruidoso. Métrica: taxa de detecção > 90% em silencioso (DoD do Blueprint Seção 11). False positive rate (decidir threshold de confidence). **Commit:** `test(voice): métricas de detecção em ambientes silencioso e ruidoso — spec-009 µ-sprint 9.6`

#### 9.7 — Validator + privacy review + session log

Confirmar que privacy manifest está completo, áudio nunca sai do device (audit de network calls durante test), telemetria sem PII. **Commit:** `docs(voice): session log + privacy review spec-009 — spec-009 µ-sprint 9.7`

### Gates específicos spec-009

- Privacy Manifest iOS validado (App Store gate)
- `researcher` confirma `SFSpeechRecognizer` `requiresOnDeviceRecognition` ainda funciona em iOS 18+
- Contract test em ambas plataformas
- Métrica de detecção registrada no session log

---

## Validação cruzada do bloco bridges

Após 007 + 008 + 009 mergeados:

- [ ] 3 Method Channels funcionais (`com.rarocamera/camera`, `/replay_buffer`, `/voice`)
- [ ] 3 ADRs novos (0016, 0017, 0018) com contratos publicados
- [ ] 3 contract.md publicados em `apps/mobile/lib/core/native_bridges/`
- [ ] iOS: SwiftLint zero, XCTest verde, `flutter build ios` ok
- [ ] Android: ktlint zero, gradle test verde, `flutter build apk` ok
- [ ] Integration test em device físico (iPhone + Pixel) verde para captura + replay + voice
- [ ] `flutter-perf-auditor` aprova consumo de RAM e frame drops aceitáveis
- [ ] P05 HUD reflete fielmente o protótipo (`design-fidelity-checker` aprova)
- [ ] Privacy Manifest iOS completo (declara speech + microphone + camera)
- [ ] Métricas de wake word em ambiente real registradas
- [ ] Smoke test do mobile + todos os testes continuam verdes
- [ ] Sessions log de cada spec em `docs/sessions/`
