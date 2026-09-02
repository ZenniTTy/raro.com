# 10-CHANGELOG — RARO

> Append-only. Header `## [YYYY-MM-DD] — version` para cada entry. Versões seguem semver.

## [2026-09-02] — APK release R8 provado no M54 (sessão 0042)

### Verificado
- **APK release no Galaxy M54 não fecha no boot.** `VoiceBackgroundService` inicia (`RaroVoice: voice background service started`, FGS `isForeground=true`); crash buffer vazio; zero `UnsatisfiedLinkError` / `jna.Pointer`. Build com Homebrew OpenJDK 21 (JBR do Android Studio ausente nesta máquina).

## [2026-09-02] — 0.9.1 (Poppins no paywall + R8 em origin, sessão 0041)

### Adicionado
- **Poppins nos cards de plano** (400/600/700). Medium (500) não era usado e não entrou no bundle.

### Corrigido
- Guard de i18n: 👑/🔥 como glifo UTF-8 (o escape `\u{...}` era falso positivo). `'RARO CAM'` allowlisted como marca, igual a `'RARO'`.
- **`5a35be4` pushado** para `origin/develop` — sem o `-keep` JNA/Vosk o APK release fecha sozinho no boot.

### Verificado
- `flutter analyze` limpo; suíte **355/355**.

## [2026-09-02] — auditoria de entrega (sessão 0040, docs-only)

> Reauditoria completa do que falta para v1.0, feita contra código/binário/git (2 agentes paralelos + verificação manual), não contra documentação. Nenhum código de produção alterado.

### Corrigido (documentação)
- **PLANO-MESTRE reescrito**: o Bloco 3 (Android) estava com tudo em aberto embora as Fatias 1–4 estivessem entregues; e o Bloco 2 estava descrito como "mock" quando na verdade **nunca foi iniciado**.
- **09-DOD.md** reconciliado item a item com evidência (`arquivo:linha`, `apksigner`, `flutter test`).

### Descoberto (drift real, com prova)
- **Suíte vermelha**: 353 passam, **1 falha** — `forbidden_ui_literals_test.dart` pega 3 literais fora do `.arb` em `plan_card.dart`. Provado por `git stash` que o commit está verde e a falha vem da árvore de trabalho (tipografia Poppins em andamento).
- **Replay buffer Android inexistente e anunciado**: `ReplayBufferHostApi` não é registrada no `MainActivity.kt`; `CameraManager.kt:176` descarta `includeReplayPreroll` com `Log.w`. A UI oferece o recurso normalmente.
- **Monetização é fachada**: `purchases_flutter` no `pubspec.yaml` com zero imports; `subscription_controller.dart:19` só grava um bool. Nenhum recurso é bloqueado por assinatura; "Restore purchases" é snackbar (bloqueador de review Apple).
- **Release Android assinado com chave de debug**: `apksigner` no `app-release.apk` retorna `CN=Android Debug` (`build.gradle.kts:40`). A Play rejeita.
- **Modo "Volume" selecionável sem implementação** em nenhuma das plataformas (`settings_screen.dart:367-370`); não existe `VolumeHostApiImpl`.
- **3 telas ausentes** (`p05aLockMode`, `p11Terms`, `p12Privacy`) e 2 modais (M02, M03) — Privacidade é obrigatória para submissão.
- **`5a35be4` (fix R8/JNA) não pushado**; `develop` está 441 commits à frente da `main`.

### Confirmado saudável
- `flutter analyze` limpo; i18n com **117 chaves × pt/en/es** e teste-guarda ativo; APK release contém `libvosk.so` + modelo pt-BR; Firebase/Crashlytics provados no device (0035).

## [2026-07-18] — 0.9.0 (Pacote pré-APK Android: gravação + tap-to-focus + voz — Fatias 1–3, provadas no M54)

> Decomposição do pré-APK em 4 fatias (Gravação → Foco → Voz → i18n). Fatias 1–3 fechadas e provadas no Galaxy M54; Fatia 4 (i18n) pendente. Sessões 0037–0038.

### Adicionado
- **Gravação Android real** (Fatia 1, PR #5): CameraX `VideoCapture<Recorder>` (`camera-video:1.6.1`, ADR-0030), MP4+áudio, thumbnail via `MediaMetadataRetriever`. Era stub. Provado via ffprobe (h264 3840×2160 + aac 48kHz estéreo).
- **Tap-to-focus Android** (Fatia 2, PR #7): tap captado no nativo (`GestureDetector.onSingleTapUp` + `meteringPointFactory`), ring de foco nativo animado por `Choreographer`, `onFocusChanged` reportando o `isFocusSuccessful` real (paridade iOS via `onFocusResult`).
- **Voz Android "raro gravar"/"raro parar"** (Fatia 3, PR #8, ADR-0029): **Vosk motor único** (`vosk-android:0.3.47` + modelo pt-BR small 31MB) via FGS `microphone` — foreground+background, um só `AudioRecord`, zero handoff. Gramática restrita no `Recognizer` + match por radical + debounce 2000ms. `POST_NOTIFICATIONS` pedido no fluxo de permissões.

### Corrigido
- **Ring de foco sumia brusco** (Fatia 2): `animator_duration_scale=0` no M54 fazia `ValueAnimator`/`AnimatorSet` pularem pro fim → animação por `Choreographer` (imune à escala).
- **Voz não reconhecia** (Fatia 3): vosk-small em reconhecimento livre não ouve a wake word "raro" e transcreve verbos aproximados ("parar"→"para") → gramática restrita (frases-alvo) + parser por radical/prefixo. Fim da detecção repetida via `recognizer.reset()` + debounce.
- **15 achados de auditoria adversarial** (4 passadas nas Fatias 2–3): drift de `onFocusChanged`, re-taps duplicando animação, use-after-free do Vosk, FGS crash, falhas silenciosas de estado, leaks de ciclo de vida.

### Arquitetura
- **Voz Android = Vosk motor único** substituiu o design de 2 motores (SpeechRecognizer nativo + Vosk com handoff) após a auditoria provar a fragilidade do handoff por tempo. `ForegroundVoiceRecognizer` removido (-213 linhas). ADR-0029 documenta.
- **Blueprint atualizado:** encoding Android distingue gravação linear (CameraX Recorder) de replay (MediaCodec futuro); voz Android passa de "não implementado" para Vosk motor único provado.

### Provado (M54, Android 16 / API 36)
- Gravação: ffprobe do clipe. Foco: ring + foco muda no tap. Voz: `[raro gravar]→START`/`[raro parar]→STOP` no log + **câmera gravou/parou por voz (confirmado na tela pelo dono)**.
- 331 testes Dart + 11 parser Kotlin verdes. Privacidade: nunca loga transcript bruto de voz.

## [2026-07-14] — 0.8.0 (Bloco 1: Firebase + Crashlytics + Analytics ligados e provados no device)

> PLANO-MESTRE Bloco 1 fechado (sessões 0034 código+build, 0035 prova no iPhone 12). Firebase deixa de ser mock/não-inicializado.

### Adicionado
- **Firebase inicializado** (`main.dart`): `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` async antes do `runApp` — sem isso o app crashava em release.
- **Crashlytics: 3 handlers** (FlutterError.onError + PlatformDispatcher.onError + Isolate error listener) — memória `raro-pattern-crashlytics-3-handlers`.
- **Plugins gradle** (DSL moderno): `com.google.gms.google-services` 4.4.4 + `com.google.firebase.crashlytics` 3.0.7 em `settings.gradle.kts` + `app/build.gradle.kts`.
- **ADR-0025** (firebase-bootstrap-strategy): registra init eager, os 3 handlers, a não-adoção de `runZonedGuarded`, e o pin dos plugins gradle.

### Corrigido
- **Analytics listener estava morto:** `cameraAnalyticsListenerProvider` era definido mas nunca observado → `RaroApp` virou `ConsumerWidget` + `ref.watch`, agora `camera_started`/`camera_error` disparam.

### Provado (gate §10, iPhone 12, 2026-07-14)
- Crash de teste → recebido no painel Crashlytics ("1 falha não processada") + 3 dSYMs subidos (UUID `A3098D9F…` bate). Builds: Android `app-debug.aab` + iOS `Runner.app` (Firebase via SPM, 16 pins). `firebase_options.dart`/plist/json gitignored — nenhum secret commitado.

### Pendência herdada (Bloco 5)
- Upload automático de dSYM em release/CI (o `flutter build` de linha de comando pode não disparar a build phase; validar no pipeline de publicação).

## [2026-06-22] — 0.7.1 (Reconciliação do harness + estado real auditado)

> Auditoria de consistência documental (3 agentes sobre código real) + correção do drift em todo o harness para as próximas sessões terem contexto verdadeiro. Roadmap vigente passa a ser `PLANO-MESTRE-finalizacao-entrega-cliente.md`.

### Mudado
- **Harness reconciliado com o estado real:** Blueprint (§2.3/§3.3/§10), ADRs 0022/0023/0024 (notas de standby/vigência), 05/06/07/09 docs, CLAUDE.md/AGENTS.md, 01/02/03/04/08/index, sprints 1-3 + PROMPTS, hook `reinject-roadmap.sh` (inventário 6→11 hooks + estado de voz), `warn-adr-drift.sh` (cobertura ampliada p/ .onnx/Voice/.swift/configs de treino).
- **Wake-word documentado honestamente:** foreground SFSpeech "raro gravar"/"raro parar" = vigente; background ONNX = STANDBY (aguarda licença Sensory). Prompt `NEXT-SESSION-voice-openwakeword` + docs ESTADO-WAKEWORD/CONTRAPONTO marcados OBSOLETO/SUPERSEDED.
- **Mocks/pendências sinalizados** em todo doc: RevenueCat (mock), Firebase (não inicializado), share ("Em breve"), i18n (0 .arb), Volume (stub), Android (não compila).
- **Lições não-mapeadas salvas** (sessões 0027-0029): corte de áudio < janela, augmentation rounds, eval sintético não é gate, N modelos = teto, etc.

## [2026-06-21] — 0.7.0 (Saga do wake-word: ONNX treinado → inviável no device → revert SFSpeech foreground)

> Sessões 0025-0029. Tentativa completa de wake-word "Raro" on-device via ONNX/openWakeWord, treino na nuvem (RunPod), e o veredito final: inviável na voz real → revert para o SFSpeech foreground que funcionava. Background fica em standby (negociação Sensory).

### Adicionado
- **Pipeline ONNX de 3 estágios (0025-0027):** `WakeWordDetector`/`WakeWordPipeline`/`OnnxModelSession` Swift + 4 modelos treinados no RunPod (livekit-wakeword 0.2.1 + VoxCPM PT-BR) + gate de recall offline (`WakeWordRecallTests`). Validado no iPhone 12.
- **Treino híbrido com voz real do dono (0029):** 213 clips reais (`real-audio/`) injetados no treino; `PLANO-MESTRE-finalizacao-entrega-cliente.md` (roadmap de finalização).
- ADR-0024 (toggle "Raro" único) + memórias técnicas de treino (RunPod, Kaggle, segmentação).

### Corrigido
- **Reconhecimento contínuo SFSpeech (0024, ADR-0022):** token de ciclo + ring buffer (NÃO reciclar por erro 1110 benigno) — 521→7 reciclos, "raro parar" parou de sumir. Validado no device.

### Mudado / Revertido
- **Wake-word "Raro" background ONNX provado INVIÁVEL no device (0029):** 4 modelos, nenhum dispara na voz real (pico 0.128, AUC máx 0.54). Causa: a palavra "Raro" (2 sílabas, muitas rimas PT-BR) é o limite do pipeline openWakeWord. **Revertido para SFSpeech foreground** (`7e9c0c9`); pipeline ONNX preservado dormente (`01a1f67`). Background = standby aguardando licença Sensory.

## [2026-06-04] — 0.6.1 (Thumbnail real na galeria — Sprint 2)

> Capa da galeria (P07) passa a ser o 1º frame real de cada vídeo do vault, no lugar do gradiente HSL (reverte decisão de design Sprint 1 para vídeos reais). Sessão 0017. Validado no iPhone 12.

### Adicionado
- **Thumbnail nativo (ADR-0019):** Pigeon `@async generateThumbnail(videoPath)→jpgPath` + `ThumbnailGenerator.swift` (`AVAssetImageGenerator`, `appliesPreferredTrackTransform`, JPEG q0.8 → `<id>.jpg` ao lado do `.mov`); gerado no save no `recordingVaultSink`; `thumbnailPath` em `RecordingMetadata`/sidecar/`VideoEntity`; `VideoThumbnail` mostra `Image.file` com fallback gradiente HSL. Android stub no-op até Sprint 3.
- `docs/decisions/0019-thumbnail-avassetimagegenerator.md` (Accepted).
- Testes: 3 XCTest nativos (`ThumbnailGeneratorTests`, inclui JPEG de `.mov` real) + Dart vault/repository/metadata/vault_sink.

### Mudado
- `videoListProvider` agora é **vault-only** (removidos os 6 `VideoEntity` mock); galeria reflete só vídeos reais gravados.
- `VaultService` escreve sidecar JSON **atomicamente** (tmp+rename) — corrige race read-during-write com a galeria.

### Corrigido
- **`ref` após dispose** no `recordingVaultSink` (listener async usava `ref.read`/`invalidate` pós-await): deps lidas no `build` + `ref.mounted` antes de `invalidate`.

## [2026-06-03] — 0.6.0 (Sprint 2 Task A — Recording real + Vault iOS)

> S2.A: a câmera virou real. P05 monta `CameraPreviewWidget` (UiKitView) ao vivo; tap REC grava `.mov` real no vault; galeria lista; preview reproduz o arquivo. Sessão 0016. Validado no iPhone 12 físico. Cobre o Sprint Goal G1 (recording funcional) — exceto a medição formal de latência <300ms (pendente).

### Adicionado
- **Recording pipeline (ADR-0018):** `RecordingPipeline.swift` (`AVCaptureMovieFileOutput`, codec HEVC fallback H264 via `setOutputSettings`) grava container `.mov` (não `.mp4`); path entregue async via `onRecordingFinished`. Áudio via `AVCaptureAudioDeviceInput`.
- **Pigeon:** `startRecording(RecordingOptions)→sessionId` + `stopRecording()` + callbacks `onRecordingFinished`/`onRecordingFailed`. Enum `Codec` em `raro_shared`. Mapper shared→pigeon (`uhd4k60`→`uhd4k`+`fps60`).
- **`VaultService`** (Dart, `Directory` injetável + sidecar JSON) salva em `documents/vault/`; `videoListProvider` lê vault; preview reproduz arquivo real (`VideoPlayerController.file` fallback `.asset`).
- `docs/decisions/0018-recording-pipeline-mp4.md` (Accepted, supersedes ADR-0015 item 7 "sem gravação").

### Mudado
- `RecordingController` promovido a Notifier reativo (`@riverpod` + escuta stream de eventos nativos + `try/finally`); preview montado só quando sessão `ready`; lens 0.5×/1× nativo; `×` removido da câmera; onboarding once-per-install.

### Notas
- **Out-of-scope (S2.B+):** replay buffer (G2), wake word, volume button, RevenueCat sandbox, share — próximas sessões do Sprint 2.

## [2026-06-02] — 0.5.0 (Sprint 1 walking skeleton iOS — 12 telas Flutter navegáveis)

> Registra o walking skeleton da Sprint 1 (Tasks D–G). Todas as telas são UI fiel ao protótipo com dados mockados via Riverpod 3 providers de signature swap-able pro Sprint 2. iOS-only, free Apple ID. Backend/lógica real = Sprint 2.

### Adicionado
- **Task D (sessão 0011):** P01 Splash (logo breathe + dot loader + tagline), P02/P03 Onboarding (mic+halos / buffer waveform), go_router com rotas do contrato `AppScreen`; fontes Space Grotesk/Inter/JetBrains Mono bundladas + logo + tokens de gradiente. Validado no iPhone 12.
- **Task E (sessão 0012):** P04 Permissions (`PermissionGateway` port + `permission_handler`), P05 Camera UI shell (HUD res/fps/lens, REC mock + timer, buffer pill, lens switcher; preview MOCK — UiKitView nativo é Sprint 2). Validado no iPhone 12.
- **Task F (sessão 0013):** P06 Settings (`RecordingSettings` freezed + `SettingsStore` port via `SharedPreferencesAsync`), P07 Gallery (6 `VideoEntity` mock, grid 3-col, thumbnails HSL, filtros client-side). Onboarding migrado pro mesmo padrão async.
- **Task G (sessão 0014):** P08 Preview (`video_player ^2.11.1` via ADR-0017, clipe mock, provider autoDispose + `ref.onDispose`, scrubber rainbow custom, `PreviewMetadata`), M01 Subscription popup (auto 450ms se `!subscribed`), P09 Paywall (2 cards selecionáveis + features + rodapé legal + watermark), P10 Checkout (tiles Apple/Google Play + CTA disabled→`subscribe`→câmera), trial countdown 30d em Settings.
- **Contrato `raro_shared`:** `PlanPricing` (9.90/89.90/7.49) + `StorageKeys.subscriptionActive`/`trialStartedAt`.
- `docs/decisions/0017-video-player-preview.md` (Accepted) + Blueprint §2.7.1 + §9 (tabela ADR completada 0015–0017).

### Mudado
- `app.dart` abre o walking skeleton via `MaterialApp.router` por padrão; harness de câmera só com `--dart-define=RARO_HARNESS=true`.
- `RaroGradients.rainbow` ganhou `stops` explícitos (fidelidade ao protótipo); novos `modalBorder`/`planCardBorder`/`paywallGlowWarm`/`Cool`.
- Persistência migrada de `SharedPreferences.getInstance()` (legado 2026) para `SharedPreferencesAsync` via ports mockáveis (Settings, Onboarding, Subscription).
- Router: stubs `_ScreenStub` substituídos por todas as telas reais e a classe removida.

### Notas
- **Device pendente (Task H):** validação física fim-a-fim das 12 telas no iPhone 12 é a próxima sessão (closure da Sprint 1).
- Copy de trial usa **30 dias** (invariante ADR-0010 + Blueprint §1 div#2); o protótipo HTML diz 15 (desatualizado).
- Suíte: 200 testes mobile + 39 shared GREEN; `flutter analyze` 0 issues; design-fidelity-checker PASS em todas as telas.

## [2026-05-29] — 0.4.2 (camera-native-bridge — G4 focus ring nativo + tap-to-focus latency collapse)

### Adicionado
- **G4 — Focus ring nativo iOS via CALayer** desenhado dentro de `CameraPlatformView` (não Flutter overlay), respeitando ADR-0015 (HUD nativo para feedback de captura). Animação fade-in/fade-out 1.2s fiel ao protótipo, registrada via `ring.add(animation, forKey:)` em `CameraManager.showFocusRing`
- `CameraManager.swift`: `focusLog` (`OSLog(subsystem: "com.rarocamera", category: "focus")`) + `os_log` em pontos do pipeline (tap recebido → conversão de coords → lockForConfiguration → setFocusPointOfInterest → callback KVO → ring shown) para instrumentar latência real no Console do Xcode em iPhone físico
- `CameraManager.installFocusKVO` instalado UMA vez em `startSession` e invalidado em `stopSession`; property `pendingFocusPoint` coordena qual tap o callback KVO de `isAdjustingFocus` deve resolver (sucesso vs timeout)
- `CameraManager.focusWasAdjusting` property em main queue serial substitui `AtomicBool` anterior (refactor `cba16ce`: KVO settle + timeout cancellation + closure-capture point corrigidos)
- **Terminal-first iOS workflow** (`354ddc3`): `apps/mobile/package.json` ganha targets `dev:ios` e `test:ios`; `apps/mobile/scripts/run-ios-native-tests.sh` auto-detecta Simulator disponível (iPhone 17/16/15/14/13 fallback) + encadeia `pub:get` + `fix-spm` antes de rodar XCTest
- `CLAUDE.md §13` nova seção "Workflow iOS — terminal-first (anti-loop SPM)": build/run/test sempre via terminal, Xcode UI restrito a signing/debug/capabilities
- 6 anti-patterns novos em `CLAUDE.md §11` documentando descobertas da sessão (infra observability antes do fix, CATransaction.setDisableActions ao redor de add(animation), CATransaction.flush vs removedOnCompletion, UiKitView sem gestureRecognizers, isSmoothAutoFocusEnabled em tap-to-focus, KVO permanente vs per-tap)
- `docs/decisions/0016-e2e-harness-hybrid.md` (Proposed): stack E2E híbrido `integration_test --machine` + Pigeon `CameraDebugHostApi` + rota `/debug/self-test` + go-ios/pymobiledevice3 + Maestro Simulator, com upgrade incremental para Patrol pós Apple Dev Program ($99/ano em 30d)
- `docs/superpowers/specs/2026-05-29-e2e-harness-hybrid-design.md` (spec Sessão 2): 6 observable goals + Q-table + out-of-scope explícito (Patrol/XCTClockMetric/MetricKit deferred)

### Mudado
- `CameraPlatformView.swift` (`d259d8c`): conversão de tap usa `captureDevicePointConverted(fromLayerPoint:)` (sensor coords), substituindo o cálculo manual aspect-ratio que causava drift no DualWide
- `camera_preview_widget.dart`: `UiKitView`/`AndroidView` com `gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new)}` (elimina ~80ms de baseline — Flutter issue #170735)
- `CameraManager.focusAtAsync` ofuscado para `sessionQueue.async` (era sync no main queue) — main thread livre para renderizar ring imediatamente após o tap (`beaeade`)
- `CameraManager.applyFocusConfig`: `isSmoothAutoFocusEnabled = false` dentro do `lockForConfiguration` durante tap (eliminando 150-400ms de ramp cinematic)
- `CameraManager.installFocusKVO`: debounce do KVO `isAdjustingFocus` reduzido de 100ms → 16ms (1 frame @60fps) — settle perceptual mantido sem custo desnecessário
- `CameraPlatformView.showFocusRing`: `setNeedsDisplay` após `addSublayer` (substituindo tentativa anterior com `CATransaction.begin/setDisableActions/commit` que falhou `testShowFocusRingAnimationsConfigured` porque `setDisableActions(true)` bloqueia a registration interna que `ring.add(animation, forKey:)` precisa)
- `camera_preview_widget.dart` (`beaeade`): chamada ao bridge nativo agora `unawaited` (fire-and-forget) — Flutter UI mostra ring otimisticamente em ≤16ms sem aguardar round-trip Pigeon

### Corrigido
- **Tap-to-focus delay perceptual em iPhone 12 colapsado em 5 root causes** (commit `3b79021` entrega o set completo):
  1. `isSmoothAutoFocusEnabled=true` adicionando ramp cinematic 150-400ms — agora `false` durante tap
  2. KVO settle debounce 100ms — agora 16ms (1 frame @60fps)
  3. `UiKitView` sem `gestureRecognizers` explícito atrasando tap propagation ~80ms (Flutter #170735) — agora reclamado via `EagerGestureRecognizer`
  4. KVO re-registrado a cada tap — agora permanente em `startSession`, coordenado por `pendingFocusPoint`
  5. Ring com `CATransaction.flush()` perdendo animation (removida pelo runtime via `removedOnCompletion=true`) — agora `setNeedsDisplay` preserva animation E força layout/render imediato
- Coordenadas de focus drifavam no DualWide porque a conversão manual usava layer bounds em vez de sensor coords (`d259d8c` troca para `captureDevicePointConverted(fromLayerPoint:)`)
- KVO timeout cancellation em race com `focusWasAdjusting` (`cba16ce`): closure-capture point ajustado + property substitui `AtomicBool` por main-queue serial

### Decidido
- **Harness E2E híbrido** (ADR-0016 Proposed) confirmado para Sessão 2: `integration_test --machine` + Pigeon `CameraDebugHostApi` + rota `/debug/self-test` guardada por `kDebugMode` + go-ios/pymobiledevice3 + Maestro Simulator para fluxos não-camera. Maestro iOS não suporta iPhone físico oficial; Patrol exige Apple Developer Program
- **Upgrade incremental para Patrol em 30d**: usuário confirmou pagamento dos $99 Apple Dev → Volume bridge + permission dialog real automation usarão Patrol após
- **Validar perceptualmente antes de instrumentar mais**: auditoria adversarial `w3cediota` (22 agents) concluiu que dos 18 itens originalmente propostos para observability, 13 eram OVERENGINEERING/DEFER, 5 HIGH_VALUE, 0 ESSENTIAL. Decisão: shipear os 5 fixes técnicos diretos e medir delay residual no iPhone 12 antes de adicionar MetricKit/XCTClockMetric/Pigeon telemetry

### Verificado
- `flutter test` mobile: **66/66 PASS** (widget + unit + contract)
- XCTest native iOS: **5/5 PASS** em iPhone 17 Pro Simulator (`CameraManagerFocus`, `CameraPlatformView`, `RunnerTests`)
- Contract tests: **30/30 PASS** via `lefthook` pre-push
- `flutter analyze` mobile: zero issues
- `lefthook` pre-commit + pre-push: GREEN em todos os 6 commits da sessão (`block-secrets`, `dart-format`, `commitlint`) — zero uso de `--no-verify`
- Push para `origin/feat/camera-native-bridge` concluído

### Pendente (Sessão 2)
- Validação perceptual manual no iPhone 12 físico
- Harness E2E híbrido camada 1 (Pigeon `CameraDebugHostApi` + rota `/debug/self-test` + `camera_tap_to_focus_test.dart`)
- Status update da spec `2026-05-28-camera-task-19-closure-design.md` para `Done`
- Addendum no ADR-0015 documentando os 5 root causes colapsados

### Pendente (em 30d, pós Apple Dev Program)
- Upgrade para Patrol cobrindo Volume bridge + permission dialog real automation

---

## [2026-05-28] — 0.4.1 (camera-native-bridge — device validation Task 19)

### Adicionado
- `apps/mobile/scripts/bootstrap-ios-permissions.sh` — idempotente; reaplica macros `GCC_PREPROCESSOR_DEFINITIONS` do `permission_handler` no `Podfile` após cada `flutter pub get` (Podfile gitignored, ADR-0014). Suporta `PERMISSION_CAMERA`, `PERMISSION_MICROPHONE`, `PERMISSION_PHOTOS`, `PERMISSION_SPEECH_RECOGNIZER`. `pod install` automático ao final
- `apps/mobile/package.json`: novo target `bootstrap:ios` (fix-spm + bootstrap-permissions combo); `pub:get` agora chama bootstrap-permissions
- `CameraManager.swift`: 3 notification observers (`wasInterruptedNotification`, `interruptionEndedNotification`, `runtimeErrorNotification`) com auto-restart em `mediaServicesWereReset` para sobreviver background/foreground
- `CameraManager.applyVirtualLensZoom`: mapping Apple-correto para iPhone DualWide (0.5x → minZoom, 1x → `virtualDeviceSwitchOverVideoZoomFactors[0]`)
- `CameraController.openSettings()` + `isPermissionPermanentlyDenied()` (delegando para `permission_handler.openAppSettings`)
- `CameraTestHarnessScreen`: `WidgetsBindingObserver` invoca `refreshAfterSettingsReturn` em `AppLifecycleState.resumed`; dialog "open settings" exibido em permission denied
- `RaroApp`: flag `_forceHarness` via `bool.fromEnvironment('RARO_HARNESS')` permite harness em release mode (default true)
- ADR-0015 addendum 2026-05-28 (seções A-H): mapping correto iPhone 12, setFormat exige `.inputPriority`, observers obrigatórios, smoothAutoFocus, permission_handler macros, Sendable warnings, err=-17281 benigno, limitações free tier, logs reais > suposições
- 4 memórias persistentes novas:
  - `raro-pattern-permission-handler-ios-podfile-macros`
  - `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping`
  - `raro-pattern-flutter-debug-vs-release-on-device`
  - `feedback_device_debug_use_real_logs_not_assumptions`

### Mudado
- `CameraManager.swift`: `selectDevice` prefere virtual device (Triple/DualWide) → fallback físico ultraWide/wide
- `CameraManager.swift`: `setFormat` agora wrapped em `beginConfiguration` + `sessionPreset = .inputPriority` + `commitConfiguration` (corrige sem-efeito antes)
- `CameraManager.swift`: `startSession` idempotente — para sessão anterior se já existir em vez de throw `alreadyRunning`
- `CameraManager.swift`: `applyFormat` ativa `isSmoothAutoFocusEnabled` (se suportado) para reduzir flicker em format switch; também aceita match aproximado (resolução mais próxima) quando exato não disponível
- `CameraManager.swift`: import `@preconcurrency AVFoundation` para suprimir warnings Sendable Swift 6
- `CameraHostApiImpl.swift`: `@unchecked Sendable` para closures `@Sendable`
- `CameraPlatformView.swift`: `layerClass` override Apple-recommended (root layer SER o preview, sincronização automática com bounds)
- `Podfile`: `post_install` define `GCC_PREPROCESSOR_DEFINITIONS` para `permission_handler` (CAMERA, MICROPHONE, PHOTOS, SPEECH_RECOGNIZER)
- `Runner.xcscheme`: Pre-action `fix-spm-ios-target.sh` (sed-only, sem `flutter build` interno — versão anterior abortava build silenciosamente)
- `CLAUDE.md §11 addendum 3`: 3 anti-patterns novos (plugin sem README iOS Setup, fix sem logs reais, debug-mode-tela é restrição arquitetural)

### Corrigido
- **Bug crítico permission_handler**: Câmera nunca aparecia em Ajustes → App porque plugin retornava `denied` silenciosamente sem chamar `AVCaptureDevice.requestAccess` (macros Podfile ausentes — best practice oficial não seguida no scaffold)
- **Lens switch sem blackout** no iPhone 12: usa virtual device + zoom mapping em vez de replace-input físico
- **setFormat sem efeito**: sessionPreset `.inputPriority` necessário
- **App crash voltando de Settings**: observers AVCaptureSession + auto-restart
- **Permission dialog não aparecia**: tratamento `isDenied` igual `isPermanentlyDenied` no iOS
- **Pre-action abortando build silenciosamente**: removido `flutter build` interno; sed-only agora

### Notas
- 6 anti-patterns adicionais catalogados em CLAUDE.md §11 (total agora cobre device debug, plugins iOS, restrições Apple+Flutter)
- Goals consolidados pós-validação iPhone 12: **G1, G2, G3, G5, G6, G8, G9 ✅** (G8/G9 via Control Center; lifecycle real fechando app → TestFlight Apple Dev Program). G4 (focus ring nativo CALayer), G7 (Instruments memória), G10 (iPad test): pendentes para próxima sessão.

---

## [2026-05-26] — 0.4.0 (camera-native-bridge)

### Adicionado
- Bridge nativo de câmera Pigeon-first (iOS AVFoundation + Android CameraX 1.6.1) com preview ao vivo, lens switch 0.5×/1×, tap-to-focus, format control (720p/1080p/4K @ 30/60fps)
- ADR-0015: estratégia da bridge nativa de câmera (VirtualCameraStrategy única iOS + CameraX 1.6.1 Android + hybrid composition + `activeFormat` manual + threading rules)
- `AnalyticsEvents`: 5 novas constantes (`cameraStarted`, `cameraStopped`, `cameraFocusTapped`, `cameraPermissionDenied`, `cameraError`)
- `BridgeChannels.cameraPreview = 'com.rarocamera/camera_preview'` (PlatformView viewType, single source of truth)
- Feature folder `apps/mobile/lib/features/camera/` (Clean Arch: domain/data/application/presentation + Riverpod 3 codegen)
- Camera UI widgets: `CameraPreviewWidget` (PlatformView + rule-of-thirds + grain), `LensChipRow` (pill chips 0.5×/1×), `FocusRingOverlay` (1.2s animação fiel ao protótipo)
- 3 contract tests novos: `ios_pbxproj_parity_test` (Swift files registrados no Xcode), `bridge_channels_parity_test` extension (`camera_preview` ↔ iOS+Android+shared), `camera_state_test` + `pigeon_camera_repository_test` + `camera_controller_test` + `camera_analytics_listener_test` + `lens_chip_row_test` + `lens_chip_row_golden_test`
- 1 hook anti-drift novo: `.claude/hooks/block-pigeon-error-rawvalue.sh` (bloqueia `String(enum.rawValue)` em PigeonError/FlutterError)

### Mudado
- `CLAUDE.md` §11: 3 novos anti-patterns proibidos (enum rawValue em Pigeon, `expect isA<T>` sem campo, swallow catch{} sem log)
- ADR-0014 addendum: confirma Podfile/Podfile.lock gitignored
- ADR-0015 addendum (pós-auditoria): PlatformView único path, threading refinado, error semantic, TDD pin

### Decidido
- iOS `VirtualCameraStrategy` única (sem `SwapInputStrategy` v1.0 — YAGNI, iPhones com 0.5× sempre expõem virtual camera)
- Android CameraX 1.6.1 (latest stable, novo motor CameraPipe — risco de regression em OEMs aceito, device test mandatório)
- PlatformView com hybrid composition Android (HUD Flutter sobre preview)
- Telemetria via camada Flutter apenas (bridge nativa não chama Firebase direto)

### Notas
- **Sem gravação** nesta spec — depende de `feat/replay-buffer-native-bridge` (pre-roll do buffer)
- `textureId` no Pigeon schema é aceito mas ignorado (PlatformView é o único preview path v1.0; reservado para migração Texture futura)
- iPad rejeitado via `deviceUnavailable` (Blueprint = iPhone only)
- Auditoria pós-Task 10 detectou + corrigiu: error code semantic loss (`String(rawValue)` → `"\(code)"`), testes só pin-tipo (10 testes pin-behavior adicionados), iOS `catch{}` sem log (adicionado `os_log`)

### Verificado
- `flutter build ios --no-codesign --debug` PASS (Runner.app gerado)
- `flutter build apk --debug` PASS (app-debug.apk gerado)
- `flutter analyze` mobile: zero issues
- `dart analyze` shared: zero issues
- `flutter test` mobile: 62 verdes (smoke + contract + features/camera)
- `dart test` shared: 33 verdes (smoke + analytics_events)
- Goldens `lens_chip_row` regenerados pós-fidelity audit (chip active solid white + pill shape)

### Pendente (device tests — Task 19 aguardando iPhone 12 do usuário)
- G1 start ≤500ms em iPhone 12 + Pixel 6
- G2 discoverCapabilities = `[ultraWide, wide]` em iPhone 12 / Pixel 6 Pro
- G3 lens switch <100ms via VirtualCameraStrategy
- G4 focus ring ≤200ms + fade 1.2s
- G5 setFormat runtime
- G6 4K@60 metadata validation
- G7 memória ±5MB pós-stop (Instruments + Memory Profiler)
- G8 permission denied UI fallback
- G9 background→foreground retoma sessão
- G10 iPad rejected graciosamente

## [2026-05-26] — 0.3.0 (flutter-3.44-spm-migration)

### Mudado
- Flutter `3.41.9` → `3.44.0` + Dart `3.11.x` → `3.12.0` (latest stable channel, ADR-0014)
- iOS deployment target `13.0` → `15.0` (perde iPhone 6s/7/8/SE 1ª geração — autorizado pelo usuário em 2026-05-26 como trade-off pela migração SPM)
- iOS dependency manager: **CocoaPods → Swift Package Manager** (Apple-native, default em Flutter 3.44, sem regressão Android)
- `apps/mobile/pubspec.yaml`: constraint `flutter: ">=3.44.0"`, `sdk: ">=3.12.0 <4.0.0"`
- `packages/shared/pubspec.yaml`: constraint `sdk: ">=3.12.0 <4.0.0"`

### Removido
- `apps/mobile/ios/Podfile`, `apps/mobile/ios/Podfile.lock` originais (CocoaPods)
- Tentativa de voltar `pigeon` para `^26.3.4` foi revertida: `theme_tailor 3.1.3` E `riverpod_lint 3.1.3` ainda pinam `analyzer ^9.0.0`. Mantido em `^26.3.2`.

### Decidido
- ADR-014: migração tríplice Flutter 3.44 + SPM + iOS 15 (ver `docs/decisions/0014-flutter-3.44-spm-ios-15.md`)

### Notas
- Plugins ainda sem SPM nativo em 2026-05-26 (`permission_handler_apple` PR #1440 não merged): Flutter 3.44 auto-gera Podfile mínimo apenas para esses. CocoaPods continua necessário (via `brew install cocoapods`, sem sudo) enquanto esses plugins não migram. `Podfile`/`Podfile.lock` gitignorados em `apps/mobile/.gitignore`.
- Material/Cupertino frozen no Flutter 3.44 (issue #184093). Imports `package:flutter/material.dart` continuam funcionando via shim. Migração para `material_ui`/`cupertino_ui` quando esses packages forem publicados (spec futura).

### Verificado
- `flutter build apk --debug` PASS (sem regressão Android — `Built build/app/outputs/flutter-apk/app-debug.apk`)
- `flutter build ios --no-codesign --debug` progrediu via SPM (`Adding Swift Package Manager integration... 227s` + `Running pod install... 5.4s` + `Xcode build done. 40s`) — gate de compile Swift validado. Build final aguarda `iOS 26.5 platform` ser baixado via Xcode > Settings > Components (issue de ambiente local, não da migração)
- 6 contract gates da spec anterior continuam verdes (14 testes em `apps/mobile/test/contract/`)
- `dart test` shared 28 verdes
- `flutter analyze` mobile zero issues (warning sobre permission_handler_apple sem SPM aceitável e esperado)

## [2026-05-26] — 0.2.0 (api-contract-shared)

### Adicionado

- **packages/shared 0.2.0**: reorganizado em 12 famílias anti-drift sob `lib/src/{identity,voice,subscription,enums,screens,analytics,storage,bridges,permissions,contract}/` com barrel único `raro_shared.dart`. ADR-0013.
- `apps/mobile`: Pigeon `^26.3.2` com 4 schemas vazios em `pigeons/` gerando código Dart + Swift + Kotlin para os bridges canônicos (`com.rarocamera/{camera,replay_buffer,voice,volume}`).
- `apps/mobile`: Theme Tailor `^3.1.3` com `RaroColors`, `RaroRadii`, `RaroSpacing`, `RaroDurations` como `ThemeExtension` em `lib/core/theme/`. `buildRaroDarkTheme()` aplicado em `MaterialApp`.
- `apps/mobile`: suite `test/contract/` com 6 gates (forbidden literals, info_plist parity, android_manifest parity, screen uniqueness, bridge parity, analytics gate). Total 14 contract tests.
- `.claude/hooks/block-forbidden-terms.sh` bloqueando `OkCamera`/variantes em Write/Edit/MultiEdit.
- `lefthook.yml`: step `contract-tests` no `pre-push` rodando `bun --filter=@raro/mobile run test:contract`.
- `apps/mobile/package.json`: script `test:contract` e `pigeon` (codegen 4 schemas).

### Corrigido

- `ios/Runner/Info.plist`: `CFBundleDisplayName` corrigido de `"Raro Mobile"` para `"Raro Camera"` (alinha com `AppIdentity.displayName`).
- `ios/Runner/Info.plist`: chaves `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` declaradas com mensagens canônicas (espelham `PermissionsContract.ios`).
- `android/app/src/main/AndroidManifest.xml`: permissions `CAMERA` e `RECORD_AUDIO` declaradas (espelham `PermissionsContract.android`).
- `apps/mobile/lib/app.dart`: removidas cores hardcoded `Color(0xFF000000)`/`Color(0xFFFFFFFF)`; passa a usar `RaroColors.dark` via ThemeExtension.
- `apps/mobile/pigeons/*.dart`: cada schema usa **sub-package Kotlin distinto** (`com.rarocamera.raro_mobile.generated.{camera,replay_buffer,voice,volume}`) para evitar `Redeclaration: class FlutterError` ao compilar Android. Sem essa separação, `flutter build apk` falha com 16 erros de Kotlin compile. Bug descoberto pós-validator e corrigido com regen + build verde.

### Pendências de ambiente

- `flutter build ios --no-codesign --debug` retorna exit 0 mas com warning de CocoaPods não instalado no ambiente de desenvolvimento atual. Schemas Swift gerados existem, mas validação completa do compile Swift requer `sudo gem install cocoapods && cd apps/mobile/ios && pod install`. Spec considerada cumprida — é setup de ambiente, não regressão de código.

### Decidido

- ADR-0013: Pigeon + Theme Tailor + gates anti-drift (triple gate: hook PreToolUse + suite test/contract/ + lefthook pre-push) como contrato canônico para 12 famílias de identificadores duplicáveis. Veja `docs/decisions/0013-pigeon-theme-tailor-and-anti-drift-gates.md`.
- Pigeon fixado em `^26.3.2` (não `26.3.4` como originalmente planejado) por conflito de constraint com `riverpod_lint 3.1.3` que exige `analyzer ^9.0.0`. Pigeon 26.3.3+ requer `analyzer >=10.0.0`. Funcionalmente idêntico; revisar em spec futura de upgrade.

### Atualizado

- `docs/Blueprint.md` Seções 2.2 (nota Pigeon após tabela Method Channels), 2.10 (3 deps em monorepo tooling), 9 (linha ADR-0013).

## [2026-05-25] — 0.1.0 (bootstrap)

### Adicionado

- Briefing imutável em `docs/briefing/original-briefing.md`
- Protótipo navegacional em `docs/briefing/prototype/Prototipo-RARO.html` + asset `raro-logo.png`
- Blueprint aprovado em `docs/Blueprint.md` com versões fixadas via Context7 + pub.dev
- Monorepo Bun + Turborepo + Biome
- `apps/mobile` Flutter 3.41 com Riverpod 3 codegen, go_router 17, RevenueCat 10, Firebase 4/12/5, alchemist + mocktail
- `packages/shared` Dart puro com constantes, enums, event names
- lefthook + commitlint (Conventional Commits, scope-enum derivado do Blueprint)
- `setup.sh` idempotente
- `AGENTS.md` + `CLAUDE.md` (manual autoritativo, 13 seções, Karpathy 4 princípios)
- `docs/01-PROJECT.md` até `09-DOD.md` (wiki base)

### Decidido

- Wake word `"Raro"` (não `"OkCamera"`)
- Free trial 30 dias
- Planos: Mensal R$ 9,90 + Anual R$ 89,90 com badge "MELHOR OFERTA"
- Native bridges custom (sem plugin `camera` oficial)
- Replay Buffer 100% nativo
- Client-only (sem backend próprio)
- Controle por botões de volume implementado; controle BT customizado fora
- Tradução em tempo real fora de escopo v1.0
- Onboarding Xiaomi híbrido (auto MIUI + manual em Settings)

### Adicionado (continuação)

- 13 ADRs em `docs/decisions/` (0000 template + 0001-0012)
- 1 session log: `docs/sessions/0001-bootstrap.md` + 0001-INDEX
- Harness completo em `.claude/`:
  - 7 subagents com `tools:` allowlist (implementer, validator,
    adr-guardian, researcher, flutter-test-author, flutter-perf-auditor,
    design-fidelity-checker)
  - 8 slash commands (commit, session-end, docs-lint, prime, new-spec,
    new-plan, verify-slice, ingest-source)
  - 7 hooks (block-env, block-secrets, format-dart, run-riverpod-codegen,
    warn-adr-drift, reinject-roadmap registrados em settings.json +
    verify-task como utilitário invocável manualmente)
  - `settings.json` com 30 entries em allow + 9 em deny + 6 hook entries
    em 3 eventos (PreToolUse, PostToolUse, SessionStart)
- Templates TLC Spec-Driven: `docs/superpowers/specs/0000-template.md`
  e `docs/superpowers/plans/0000-template.md`
- `CLAUDE.md` Seção 6 com workflow auto-sizing (quick/medium/large) +
  sinais que escalam fatia + primeira spec sugerida

### Corrigido (sprints retroativos)

- Sprint 2.7-fixes: 5 fixes pós-Fase 3 (trial 30d direto, hook
  dart-format sem cd quebrado, warning 14 packages explicado em ADR,
  smoke test com guards reais, README.md)
- Sprint 4.7-fixes: 5 fixes pós-Fase 4 (`$schema` URL inexistente
  removido, Stop event teatral removido, analyze-changed-dart
  redundante removido, warn-adr-drift sem blacklist hardcoded,
  setup.sh valida python3)

### Bootstrap status

**v0.1.0 bootstrap completo em 30 commits.** Próximo passo: criar
primeira spec via `/new-spec camera-native-bridge` (Roadmap prioridade 1).
