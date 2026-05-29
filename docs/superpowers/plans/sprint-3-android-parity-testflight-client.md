# Sprint 3 — Android Parity + TestFlight + Polish + Entrega Cliente (Detailed Execution Plan)

> **REQUIRED SUB-SKILL** para sessões de execução: `superpowers:subagent-driven-development`. Tasks usam checkbox `- [ ]`.

**Goal**: Atingir paridade Android com iOS (Sprint 2), pagar Apple Developer Program ($99/ano), shippar build TestFlight, criar Google Play Console internal testing track, convidar cliente e entregar app testável em **AMBAS plataformas**.

**Arquitetura**: Native bridges Android (Kotlin/CameraX) paralelos aos iOS Sprint 2. Pigeon channels já existem (são plataforma-agnósticos); Android implementa o lado nativo. Riverpod providers não mudam — bridges retornam mesmo data shape. CI/CD pipelines pra TestFlight + Google Play Internal Testing.

**Tech Stack**: + Kotlin/CameraX 1.6.1 (camera + recording), `MediaCodec` (replay buffer), Android SpeechRecognizer (wake word), `AudioManager` STREAM_MUSIC (volume), `BillingClient` (RevenueCat handles), Crashlytics/Analytics Firebase (já configurado). i18n via Flutter ARB + `intl` codegen.

---

## Contexto

**Estado de entrada (depois de Sprint 2)**:
- iOS app funcionalmente completo no iPhone 12 (free Apple ID)
- `develop` contém todas features iOS reais (recording, replay, wake word, volume, paywall sandbox, share, vault)
- Android: ainda nenhuma feature implementada além do scaffold inicial do Flutter projeto
- Apple Dev Program ainda não pago (usuário confirmou disposição em 30d)
- Cliente ainda não tem acesso ao app

**Estado de saída (depois de Sprint 3)**:
- Android paridade completa com iOS: todas features funcionais em device Android (preferencialmente um Xiaomi/Samsung pra cobrir corner cases)
- Apple Dev Program pago ($99/ano)
- TestFlight build aprovado + cliente convidado por email (capacidade até 10k testers)
- Google Play Console Internal Testing track ativo + cliente convidado
- i18n PT/ES/EN funcional (locale switching em settings)
- P12 Xiaomi MIUI modal + P13 Bluetooth modal + P14 Lock mode implementados
- Crashlytics events + Analytics events conforme ADR-0013
- Performance gates: golden tests + integration_test E2E via Pigeon `CameraDebugHostApi` (ADR-0016)

---

## Pre-flight checklist

- [ ] Sprint 2 concluído: Blueprint §11 todos checkboxes Sprint 2 ✅
- [ ] iPhone 12 funcional com Sprint 2 features (smoke test final passou)
- [ ] **Device Android disponível**: preferir Xiaomi com MIUI/HyperOS (cobre memória `raro-pattern-xiaomi-miui-hyperos-detection`) + um Samsung secundário. Mínimo um. Conectar via USB com USB debugging ativo.
- [ ] **Google Play Console account**: usuário tem (ou cria — $25 taxa única) acesso a https://play.google.com/console/
- [ ] **Apple Dev Program**: usuário pagou ou está prestes a pagar $99 (Task B0 abaixo)
- [ ] **App Store Connect access** (vem com Apple Dev pago) + bundle ID `com.rarocamera` registrado
- [ ] `flutter analyze` + `flutter test` em `apps/mobile/` → 0 issues / PASS
- [ ] Audit deste MD rodado por agente fresh (ver "Audit checklist" no final)

---

## Sprint Goals (observáveis binários)

- **G1 — Android Camera funcional**: app instala em Xiaomi/Samsung, preview funciona, lens switch (0.5x/1x onde disponível — memória avisa que Android CameraX ultra-wide é unreliable, esconder botão se não disponível), tap-to-focus, format setting.
- **G2 — Android Recording + Replay funcional**: paridade com iOS Sprint 2 (REC grava MP4, replay buffer 15s/30s, salvar replay).
- **G3 — Android Wake word + Volume funcional**: wake word "Raro" via Android SpeechRecognizer, volume button via AudioManager STREAM_MUSIC observer.
- **G4 — Android RevenueCat paywall funcional**: BillingClient via RevenueCat, products Google Play sandbox.
- **G5 — TestFlight build instalável**: cliente recebe email TestFlight, instala, abre, faz fluxo end-to-end.
- **G6 — Google Play Internal Testing instalável**: cliente acessa link Play Store internal track, instala, abre, fluxo end-to-end.
- **G7 — i18n PT/ES/EN funcional**: locale switch em Settings muda toda UI; restart preserva escolha.
- **G8 — P12 Xiaomi + P13 Bluetooth + P14 Lock mode**: modais aparecem em condições corretas (Xiaomi detected, Bluetooth control conectado, lock mode ativado).
- **G9 — Crashlytics + Analytics funcionais**: eventos definidos em ADR-0013 sendo emitidos; crash de teste aparece em Firebase Console.
- **G10 — Performance gates GREEN**: golden tests cobrindo telas-chave passam; integration_test E2E via Pigeon `CameraDebugHostApi` passa em ambos device físico e Simulator/Emulator.

---

## Sessões previstas

| # | Objetivo | Entregável | Files principais |
|---|---|---|---|
| **S3.A** | Apple Dev Program signup + bundle ID config | $99 pago, ASC config | `apps/mobile/ios/Runner.xcodeproj/...` (signing) |
| **S3.B** | Android Camera bridge (CameraX preview + lens + focus + format) | preview + lens + focus em Xiaomi/Samsung | `apps/mobile/android/app/src/main/kotlin/com/rarocamera/camera/` |
| **S3.C** | Android Recording + Vault | MP4 grava + lista em Gallery | `apps/mobile/android/.../camera/RecordingPipeline.kt`, vault swap |
| **S3.D** | Android Replay buffer | Buffer 15s/30s + save replay | `apps/mobile/android/.../camera/ReplayBuffer.kt` (MediaCodec circular) |
| **S3.E** | Android Wake word + Volume | "Raro" + volume button | `apps/mobile/android/.../voice/`, `apps/mobile/android/.../volume/` |
| **S3.F** | Android Paywall + Google Play setup | BillingClient + Internal Testing | `apps/mobile/android/.../billing/`, Play Console |
| **S3.G** | i18n PT/ES/EN | ARB + intl codegen + locale switch | `apps/mobile/lib/l10n/`, `apps/mobile/lib/core/locale_provider.dart` |
| **S3.H** | Modais P12/P13/P14 + Crashlytics + Analytics | 3 modais + events working | `lib/features/onboarding/widgets/`, `lib/core/analytics/` |
| **S3.I** | Performance gates: golden tests + integration_test E2E | CI gates green | `apps/mobile/test/goldens/`, `apps/mobile/integration_test/` |
| **S3.J** | TestFlight build + cliente convidado | Cliente testa em iPhone | TestFlight pipeline + email convite |
| **S3.K** | Google Play Internal Testing + cliente convidado | Cliente testa em Android | Play Console pipeline + email convite |
| **S3.L** | Smoke test final cliente + retro Sprint 3 | App entregue | Session log + Blueprint final |

---

## Tasks atômicas

### Task A — Apple Dev Program signup (S3.A)

#### A1. Pagamento Apple Dev Program

**Files**: nenhum (transação externa).

**DONE criteria**: usuário recebe email confirmação Apple Dev Program activated. App Store Connect mostra access ativo.

- [ ] **Step 1**: Usuário acessa https://developer.apple.com/programs/ → "Enroll" → individual account.
- [ ] **Step 2**: Pagamento $99 USD via cartão.
- [ ] **Step 3**: Aguardar email confirmação (pode levar até 48h em alguns casos).

#### A2. Bundle ID + Provisioning Profile setup

**Files**: signing via Xcode UI (uma das exceções legítimas a §13 terminal-first).

**DONE criteria**: bundle ID `com.rarocamera` registrado em App Store Connect; provisioning profile gerado; Xcode usa profile.

- [ ] **Step 1**: App Store Connect → My Apps → "+" → Novo app:
  - Platform: iOS
  - Name: "Raro Câmera"
  - Bundle ID: `com.rarocamera`
  - SKU: `raro-camera-ios`
- [ ] **Step 2**: Em Xcode → Runner project → Signing & Capabilities → Team: selecionar Apple Dev account → "Automatically manage signing" ativado.
- [ ] **Step 3**: Build release config funciona:
  ```bash
  cd apps/mobile && flutter build ios --release
  ```
  Esperado: build succeeds sem signing errors.

#### A3. App Store Connect produtos in-app

**Files**: nenhum (config externa).

**DONE criteria**: 2 produtos in-app criados em App Store Connect, free trial 30d configurado conforme ADR-0010.

- [ ] **Step 1**: App Store Connect → seu app → Features → In-App Purchases → "+":
  - Auto-Renewable Subscription → Subscription Group "Raro Pro"
  - Product 1: `com.rarocamera.monthly`, R$ 9,90, Free Trial 30 days
  - Product 2: `com.rarocamera.yearly`, R$ 89,90, Free Trial 30 days
- [ ] **Step 2**: Cada produto: review information + screenshot (preparar pré-Sprint 3).

---

### Task B — Android Camera bridge (S3.B)

#### B1. Android Manifest + Gradle setup

**Files**:
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml` (permissions camera + microphone)
- Modify: `apps/mobile/android/app/build.gradle.kts` (CameraX 1.6.1 deps)

**DONE criteria**: `bun --filter @raro/mobile run dev:android -- -d <android-udid>` builda sem erros.

- [ ] **Step 1**: Manifest permissions:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-feature android:name="android.hardware.camera" android:required="true" />
  ```
- [ ] **Step 2**: Build.gradle.kts deps:
  ```kotlin
  dependencies {
      implementation("androidx.camera:camera-core:1.6.1")
      implementation("androidx.camera:camera-camera2:1.6.1")
      implementation("androidx.camera:camera-lifecycle:1.6.1")
      implementation("androidx.camera:camera-view:1.6.1")
      implementation("androidx.camera:camera-video:1.6.1")
  }
  ```
  Versão **pinada** conforme ADR-0015.

#### B2. CameraManager.kt + PlatformView

**Files**:
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/camera/CameraManager.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/camera/CameraPlatformView.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/camera/CameraPlatformViewFactory.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/MainActivity.kt` (registrar factory)
- Create: `apps/mobile/android/app/src/androidTest/kotlin/com/rarocamera/camera/CameraManagerTest.kt`

**DONE criteria**: Pigeon camera_api implementação Android funcional; preview aparece em Xiaomi; lens switch funciona em devices que suportam ultra-wide (esconder se não); androidTest passa.

- [ ] **Step 1**: CameraManager esqueleto:
  ```kotlin
  class CameraManager(private val context: Context) {
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var preview: Preview? = null
    
    fun startSession(lifecycleOwner: LifecycleOwner, lens: LensFacing): Result<Unit> {
      // ProcessCameraProvider.getInstance(context)
      // bindToLifecycle com preview + analysis + video capture
    }
    
    fun switchLens(target: LensFacing): Result<Unit> {
      // unbind + bind com novo selector
    }
    
    fun applyFocus(point: PointF): Result<Unit> {
      // CameraX FocusMeteringAction
    }
    
    fun availableLenses(): List<LensFacing> {
      // CameraInfo.physicalCameraIds + characteristics CAPABILITY_LOGICAL_MULTI_CAMERA
      // memória: ultra-wide unreliable por OEM, return apenas as disponíveis
    }
  }
  ```
- [ ] **Step 2**: PlatformView e Factory registrar.
- [ ] **Step 3**: Implementar Pigeon Camera HostApi side Android (em `MainActivity.kt` ou class dedicada).
- [ ] **Step 4**: androidTest cobrindo: startSession, switchLens (se device suporta), applyFocus.
- [ ] **Step 5**: Smoke manual em Xiaomi e Samsung: preview funciona, lens switch funciona ou botão escondido.
- [ ] **Step 6**: Commit: `feat(camera-android): camerax preview + lens + focus + format paridade ios`.

---

### Task C — Android Recording + Vault swap (S3.C)

#### C1. RecordingPipeline.kt usando CameraX VideoCapture

**Files**:
- Create: `apps/mobile/android/.../camera/RecordingPipeline.kt`
- Modify: CameraManager.kt (integrar pipeline)
- Create: `apps/mobile/android/app/src/androidTest/.../RecordingPipelineTest.kt`

**DONE criteria**: androidTest valida que start → stop produz MP4 H.264 no `Environment.getExternalFilesDir()/Movies/raro/`; smoke test em Xiaomi grava 3s e reproduz.

- [ ] **Step 1**: Pipeline:
  ```kotlin
  class RecordingPipeline(private val camera: Camera, private val videoCapture: VideoCapture<Recorder>) {
    private var activeRecording: Recording? = null
    
    fun start(outputFile: File, codec: VideoCodec, fps: Int): Result<Unit> {
      val outputOptions = FileOutputOptions.Builder(outputFile).build()
      activeRecording = videoCapture.output
        .prepareRecording(context, outputOptions)
        .start(executor) { event ->
          // handle events
        }
      return Result.success(Unit)
    }
    
    fun stop(): File? {
      activeRecording?.stop()
      return outputFile
    }
  }
  ```
- [ ] **Step 2**: androidTest com 2s recording + assert file exists + size > 1KB.
- [ ] **Step 3**: Vault Dart side já suporta — Pigeon retorna path, vault_service.save copia pra `getApplicationDocumentsDirectory()`.
- [ ] **Step 4**: Smoke iPhone vs Android: vídeo gravado em Android aparece na Gallery cross-platform.
- [ ] **Step 5**: Commit: `feat(camera-android): real recording pipeline camerax videocapture + androidtest`.

---

### Task D — Android Replay buffer (S3.D)

#### D1. Memória relevante: `raro-pattern-android-mediacodec-buffer-management`

Reler: MediaCodec já é pool-based, não inventar pool ByteBuffer.

#### D2. ReplayBuffer.kt usando MediaCodec circular

**Files**:
- Create: `apps/mobile/android/.../camera/ReplayBuffer.kt`
- Create: `apps/mobile/android/app/src/androidTest/.../ReplayBufferTest.kt`

**DONE criteria**: androidTest valida que após 30s de captura simulada, `save()` produz MP4 ~30s do trailing window; memória manda guardar bytes encoded em deque circular usando `dequeueInputBuffer`/`releaseOutputBuffer`.

- [ ] **Step 1**: Esqueleto:
  ```kotlin
  class ReplayBuffer(private val bufferSeconds: Int) {
    private val encoded = ArrayDeque<EncodedFrame>(capacity = estimateBytes(bufferSeconds))
    private val mediaCodec = MediaCodec.createEncoderByType("video/avc")
    
    fun append(frame: ByteArray, presentationTimeUs: Long) {
      // input via dequeueInputBuffer
      // collect output via releaseOutputBuffer (bytes encoded)
      // adicionar à deque + trim mais velhos se ultrapassou janela
    }
    
    fun save(outputFile: File): Result<Unit> {
      // muxer (MediaMuxer) com bytes da deque
    }
  }
  ```
- [ ] **Step 2**: androidTest.
- [ ] **Step 3**: Smoke Xiaomi.
- [ ] **Step 4**: Commit: `feat(replay-android): replay buffer mediacodec circular dequeue paridade ios`.

---

### Task E — Android Wake word + Volume (S3.E)

#### E1. Wake word "Raro" via Android SpeechRecognizer

**Files**:
- Create: `apps/mobile/android/.../voice/WakeWordDetector.kt`
- Create: `apps/mobile/android/app/src/androidTest/.../WakeWordDetectorTest.kt`

**DONE criteria**: detector dispara `onWakeWordDetected` quando transcript contém "raro"; restart loop (Android SpeechRecognizer tem timeout silêncio).

- [ ] **Step 1**: Esqueleto:
  ```kotlin
  class WakeWordDetector(private val context: Context) : RecognitionListener {
    private val recognizer = SpeechRecognizer.createSpeechRecognizer(context)
    
    fun start() {
      val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        .putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
        .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      recognizer.setRecognitionListener(this)
      recognizer.startListening(intent)
    }
    
    override fun onPartialResults(partialResults: Bundle?) {
      val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
      val transcript = matches?.firstOrNull()?.lowercase()
      if (transcript?.matches(Regex("\\braro\\b")) == true) {
        VoiceFlutterApi.shared?.onWakeWordDetected()
      }
    }
    
    override fun onEndOfSpeech() {
      // restart loop pra contornar timeout silêncio
      recognizer.startListening(intent)
    }
    
    // ... other RecognitionListener methods
  }
  ```
- [ ] **Step 2**: androidTest mock RecognitionListener.
- [ ] **Step 3**: Smoke Xiaomi.
- [ ] **Step 4**: Commit: `feat(voice-android): wake word raro speechrecognizer restart loop pt-br`.

#### E2. Volume button via AudioManager STREAM_MUSIC observer

**Files**:
- Create: `apps/mobile/android/.../volume/VolumeWatcher.kt`
- Create: androidTest correspondente

**DONE criteria**: pressionar volume +/- emite evento; volume mantém-se no valor inicial (não muda audição); smoke test.

- [ ] **Step 1**: VolumeWatcher esqueleto:
  ```kotlin
  class VolumeWatcher(private val context: Context) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val initialVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    private var contentObserver: ContentObserver? = null
    
    fun start() {
      contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
          val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
          val direction = if (current > initialVolume) "up" else "down"
          // restaurar
          audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, initialVolume, 0)
          VolumeFlutterApi.shared?.onVolumePressed(direction = direction)
        }
      }
      context.contentResolver.registerContentObserver(
        Settings.System.CONTENT_URI, true, contentObserver!!
      )
    }
    
    fun stop() {
      contentObserver?.let { context.contentResolver.unregisterContentObserver(it) }
    }
  }
  ```
- [ ] **Step 2**: androidTest.
- [ ] **Step 3**: Smoke Xiaomi.
- [ ] **Step 4**: Commit: `feat(volume-android): volume watcher audiomanager stream_music + restore`.

---

### Task F — Android RevenueCat + Google Play Console (S3.F)

#### F1. Google Play Console signup

**Files**: nenhum.

**DONE criteria**: usuário tem acesso ao Console, $25 taxa única paga, app `com.rarocamera` registrado.

- [ ] Usuário acessa https://play.google.com/console/ → pagar $25 (taxa única, lifetime) → criar Developer profile.
- [ ] Criar app: nome "Raro Câmera", default language pt-BR.

#### F2. Products + Internal Testing track

**Files**: nenhum (config externa).

**DONE criteria**: 2 products in-app (subscription) criados; Internal Testing track ativo.

- [ ] **Step 1**: Products: `com.rarocamera.monthly` (R$ 9,90, trial 30d), `com.rarocamera.yearly` (R$ 89,90, trial 30d).
- [ ] **Step 2**: Internal Testing → criar track + adicionar email do cliente como tester + dele aceitar invite.

#### F3. BillingClient via RevenueCat

**Files**:
- Modify: `lib/core/billing/revenuecat_initializer.dart` (já existe Sprint 2 — adicionar Android API key)
- Modify: `apps/mobile/android/app/build.gradle.kts` (purchases_flutter dependency já vem do Flutter, validar)

**DONE criteria**: Android paywall mostra produtos reais via RevenueCat; smoke purchase com sandbox tester funciona.

- [ ] **Step 1**: RevenueCat dashboard → add Android API key apontando pra Google Play product IDs.
- [ ] **Step 2**: Initializer:
  ```dart
  if (Platform.isAndroid) {
    await Purchases.configure(PurchasesConfiguration('goog_xxxxx'));
  } else if (Platform.isIOS) {
    await Purchases.configure(PurchasesConfiguration('appl_xxxxx'));
  }
  ```
- [ ] **Step 3**: Smoke purchase em Xiaomi com Google Play test account.
- [ ] **Step 4**: Commit: `feat(paywall-android): revenuecat google play billing + sandbox purchase`.

---

### Task G — i18n PT/ES/EN (S3.G)

#### G1. Memória relevante: `raro-pattern-flutter-i18n-synthetic-package-false`

Confirmar: `synthetic-package: false` em 2026 (gera source tree navegável).

#### G2. l10n config + ARB files

**Files**:
- Modify: `apps/mobile/pubspec.yaml` (l10n section)
- Create: `apps/mobile/l10n.yaml`
- Create: `apps/mobile/lib/l10n/app_pt.arb`
- Create: `apps/mobile/lib/l10n/app_es.arb`
- Create: `apps/mobile/lib/l10n/app_en.arb`

**DONE criteria**: codegen gera classes ARB; UI usa `AppLocalizations.of(context).strings`.

- [ ] **Step 1**: `l10n.yaml`:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_pt.arb
  output-localization-file: app_localizations.dart
  synthetic-package: false
  output-dir: lib/l10n/generated
  ```
- [ ] **Step 2**: Migrar strings hard-coded de telas pra ARB.
- [ ] **Step 3**: Rodar `flutter gen-l10n`.

#### G3. Locale provider + Settings switch

**Files**:
- Create: `apps/mobile/lib/core/locale_provider.dart`
- Modify: `apps/mobile/lib/features/settings/presentation/settings_screen.dart` (locale picker existente Sprint 1 — agora liga ao provider)

**DONE criteria**: troca locale em Settings → UI refresh imediato; restart preserva.

- [ ] Commit: `feat(i18n): pt/es/en arb + locale_provider + settings switch`.

---

### Task H — Modais P12/P13/P14 + Crashlytics + Analytics (S3.H)

#### H1. P12 Xiaomi MIUI modal

**Files**:
- Create: `apps/mobile/lib/features/onboarding/presentation/widgets/xiaomi_modal.dart`
- Create: `apps/mobile/lib/core/device_detector.dart` (detect Xiaomi/MIUI/HyperOS via `device_info_plus`)

**DONE criteria**: modal aparece em iPhone? NO. Em Pixel/Samsung? NO. Em Xiaomi com MIUI/HyperOS? YES — 4-step battery optimization guide.

- [ ] Memória `raro-pattern-xiaomi-miui-hyperos-detection` aplicar: `manufacturer == "Xiaomi"` detecta MIUI E HyperOS.
- [ ] Commit: `feat(onboarding): p12 xiaomi miui battery modal + detector`.

#### H2. P13 Bluetooth control modal

**Files**:
- Create: `apps/mobile/lib/features/onboarding/presentation/widgets/bluetooth_modal.dart`

**DONE criteria**: modal informativo (não funcional — bluetooth control externo é defer pós-Sprint 3).

- [ ] Commit: `feat(onboarding): p13 bluetooth control modal informativo`.

#### H3. P14 Lock mode

**Files**:
- Create: `apps/mobile/lib/features/camera/presentation/lock_mode_screen.dart`

**DONE criteria**: usuário ativa lock mode em Camera → fullscreen timer overlay (REC-only), gestures bloqueados exceto stop button.

- [ ] Commit: `feat(camera): p14 lock mode fullscreen timer + gesture lock`.

#### H4. Crashlytics events conforme ADR-0013

**Files**:
- Modify: `apps/mobile/lib/core/analytics_service.dart`

**DONE criteria**: eventos 12 famílias do `packages/shared/lib/src/events/analytics_events.dart` emitidos corretamente; crash de teste aparece em Firebase Console em ≤5min.

- [ ] **Step 1**: Implementar emissão pra cada evento (camera_started, recording_saved, replay_saved, wake_word_detected, etc.).
- [ ] **Step 2**: Crash de teste:
  ```dart
  // dev-only botão
  FirebaseCrashlytics.instance.crash();
  ```
- [ ] **Step 3**: Verificar em https://console.firebase.google.com.
- [ ] **Step 4**: Commit: `feat(analytics): emit 12 event families + crashlytics breadcrumbs`.

---

### Task I — Performance gates (S3.I)

#### I1. Golden tests para telas-chave

**Files**:
- Create: `apps/mobile/test/goldens/splash_golden_test.dart`
- Create: `apps/mobile/test/goldens/camera_golden_test.dart`
- Create: `apps/mobile/test/goldens/paywall_golden_test.dart`
- Create: `apps/mobile/test/goldens/gallery_golden_test.dart`

**DONE criteria**: `alchemist` rodando gera goldens; diff visual em PR mostra renders pixel-perfect.

- [ ] **Step 1**: Usar `alchemist` package (já em devDeps).
- [ ] **Step 2**: Gerar goldens iniciais:
  ```bash
  bun --filter @raro/mobile run test -- --update-goldens
  ```
- [ ] **Step 3**: Verify visual.

#### I2. Integration test E2E via Pigeon `CameraDebugHostApi` (ADR-0016)

**Files**:
- Create: `apps/mobile/pigeons/camera_debug_api.dart` (NOVA)
- Create: `apps/mobile/integration_test/camera_tap_to_focus_test.dart`
- Create: `apps/mobile/integration_test/recording_flow_test.dart`

**DONE criteria**: integration_test --machine roda em iPhone 12 físico em ~90s; valida tap-to-focus + recording flow end-to-end com assertions deterministas (não subjetividade visual).

- [ ] **Step 1**: Pigeon debug API:
  ```dart
  @HostApi()
  abstract class CameraDebugHostApi {
    CGPoint? getFocusPointOfInterest();
    String getCurrentLens();
    double getZoomFactor();
  }
  ```
  **Guard por `#if DEBUG` em Swift / `BuildConfig.DEBUG` em Kotlin** — não vai em release.
- [ ] **Step 2**: Tests:
  ```dart
  testWidgets('Tap-to-focus moves focus point to expected sensor coord', (tester) async {
    // ...
    await tester.tap(find.byKey(Key('camera_preview')), at: Offset(100, 200));
    await tester.pump();
    final focusPoint = await CameraDebugHostApi().getFocusPointOfInterest();
    expect(focusPoint, isNotNull);
    // assert dentro de tolerância
  });
  ```
- [ ] **Step 3**: Rodar `flutter test integration_test --machine` em iPhone 12 + Xiaomi.
- [ ] **Step 4**: Commit: `feat(testing): camera_debug_host_api + integration_test e2e tap-to-focus + recording`.

---

### Task J — TestFlight build + cliente convidado (S3.J)

#### J1. Build release iOS + upload

**Files**: nenhum (CI/CD).

**DONE criteria**: build aparece em TestFlight; cliente recebe email.

- [ ] **Step 1**: Pre-flight: incrementar versão em `pubspec.yaml` (e.g., 1.0.0+1 → 1.0.0+2).
- [ ] **Step 2**: Build release:
  ```bash
  cd apps/mobile
  flutter build ipa --release
  ```
- [ ] **Step 3**: Upload via Xcode UI: Window → Organizer → Apps → "Distribute App" → App Store Connect → Upload.
  - Alternativa CLI (recomendado pra automação Sprint 3+): `xcrun altool --upload-app -f build/ios/ipa/raro-camera.ipa -u <apple-id> -p <app-specific-password>`
- [ ] **Step 4**: Aguardar processing em App Store Connect (~15min).
- [ ] **Step 5**: TestFlight tab → "External Testing" → adicionar tester (email cliente) + Review request (Apple aprova em 24h tipicamente).
- [ ] **Step 6**: Aguardar approve + cliente recebe email TestFlight.

#### J2. Cliente baixa TestFlight + smoke test

**Files**: nenhum.

**DONE criteria**: cliente instala app via TestFlight, abre, completa fluxo end-to-end (splash → onboarding → permissions → camera → REC → gallery → paywall).

- [ ] Documentar feedback do cliente.

---

### Task K — Google Play Internal Testing + cliente (S3.K)

#### K1. Build release Android + upload

**Files**: nenhum (CI/CD).

**DONE criteria**: AAB aparece em Internal Testing; link instalação enviado pro cliente.

- [ ] **Step 1**: Build AAB:
  ```bash
  cd apps/mobile
  flutter build appbundle --release
  ```
- [ ] **Step 2**: Upload em Play Console → Internal Testing → Create new release → upload `build/app/outputs/bundle/release/app-release.aab`.
- [ ] **Step 3**: Submit → aguardar review (Internal Testing review ≤24h Google).
- [ ] **Step 4**: Compartilhar opt-in link com cliente: `https://play.google.com/apps/internaltest/<token>`.

#### K2. Cliente instala + smoke test Android

**Files**: nenhum.

**DONE criteria**: cliente instala, abre, completa fluxo end-to-end no Android.

---

### Task L — Smoke test final cliente + retro (S3.L)

#### L1. End-to-end cliente both platforms

**DONE criteria**: cliente confirma que conseguiu testar 100% do app em ambas plataformas; lista de bugs encontrados (se algum) registrada como issues no repo.

#### L2. Blueprint §11 + session log Sprint 3 closure

**Files**:
- Modify: `docs/Blueprint.md §11` (todos checkboxes Sprint 3 ✅)
- Create: `docs/sessions/<NNNN>-sprint3-closure.md`
- Modify: `docs/sessions/0001-INDEX.md`

**DONE criteria**: Blueprint mostra v1.0 candidata pra App Store + Play Store submission.

- [ ] Commit final: `docs(sprint-3): blueprint v1.0 ready + session log closure + cliente entregue`.

---

## Riscos conhecidos

| Risco | Mitigação |
|---|---|
| Xiaomi/Samsung CameraX ultra-wide unreliable (memória) | Esconder botão 0.5x se `availableLenses()` não retornar ultra-wide. |
| Android SpeechRecognizer pt-BR timeout silêncio agressivo | Restart loop `onEndOfSpeech` callback. Limite quota: SpeechRecognizer não tem quota igual iOS, mas pode comer bateria — escopar para apenas quando camera ativa. |
| Volume KVO Android via ContentResolver pode race com app audio | Categoria `STREAM_MUSIC` + restore imediato. Testar em Xiaomi (MIUI custom audio routing). |
| RevenueCat Google Play products demoram pra propagar | Aguardar até 24h após criar em Play Console antes de testar via SDK. |
| TestFlight review external rejection (privacy policy, screenshots faltando) | Preparar privacy policy + screenshots PRÉ-Sprint 3 (deveria fazer em S3.A). |
| Play Store Internal Testing requer assinatura de release | Configurar keystore + signing config em `apps/mobile/android/key.properties` (gitignored). |
| i18n strings extraction pode quebrar UI (texto cortado em DE/EN) | Smoke test em cada locale após codegen. |
| Crashlytics events não aparecem em Firebase Console | Verificar configuração `GoogleService-Info.plist` (iOS) + `google-services.json` (Android) presentes. Memória `raro-pattern-crashlytics-3-handlers` aplicável. |
| integration_test E2E lento (>5min) trava CI | Limitar testes E2E a fluxos críticos (tap-to-focus + recording). Skip iOS+Android pra mesmo PR — alternar. |
| Cliente reporta bug critical no smoke test | Hotfix branch dedicada + fast-track via Play Store/TestFlight track. Não bloquear Sprint 3 closure. |
| Google Play Console $25 nunca pago | Validar EARLY (Pre-flight checklist). Se cliente não pagou, sprint não pode iniciar Task F1. |

---

## Out of scope (vira pós-Sprint 3 backlog)

- ✗ App Store + Play Store **production submission** (Sprint 3 entrega Internal Testing apenas; production = nova fase)
- ✗ Bluetooth control real device (P13 ficou informativo)
- ✗ Volume button durante background recording (Sprint 3 só foreground)
- ✗ Wake word durante background (idem — Android impossibilita; iOS exige `audio` background mode no `Info.plist`)
- ✗ Web Distribution EU (regulação 2024 — pós-launch)
- ✗ Localizações além PT/ES/EN
- ✗ Tablet/iPad layouts otimizados
- ✗ Apple Watch / Wear OS companion app

---

## Audit checklist (rodar no início de sessão de execução Sprint 3)

> Audite `docs/superpowers/plans/sprint-3-android-parity-testflight-client.md` contra:
> 1. Sprint 2 está completo? Blueprint §11 todos Sprint 2 checkboxes ✅?
> 2. Apple Dev Program pago (recibo do usuário)?
> 3. Google Play Console $25 pago?
> 4. Memórias Android (`raro-pattern-android-camerax-ultra-wide-unreliable`, `raro-pattern-android-mediacodec-buffer-management`, `raro-pattern-android-13-media-permissions`, `raro-pattern-xiaomi-miui-hyperos-detection`) existem em memory/?
> 5. ADR-0015 (camera bridge), ADR-0016 (E2E harness hybrid) existem?
> 6. CameraX 1.6.1 ainda é versão atual (não foi releasado breaking change)? Validar via WebSearch + Context7.
> 7. RevenueCat Android SDK + Apple SDK API atual? Pesquisar Context7.
> 8. TestFlight pipeline tem todos requirements (privacy policy URL, screenshots, app icon 1024x1024, etc.) prontos?
> 9. Pigeon `CameraDebugHostApi` (ADR-0016) implementação Android paralela ao iOS está spec'd?
> 10. Goals G1-G10 binários e mensuráveis?
> 11. Placeholders/TODOs em alguma task?
>
> Report ≤500 palavras. Se 0 holes, "Audit clean, pode executar Task A1".

Se ≥1 hole, corrigir antes de A1.

---

## Em palavras simples

**O que Sprint 3 entrega**: o cliente recebe um email do TestFlight (iOS) e um link do Google Play Internal Testing (Android). Ele clica, instala o app, abre, e consegue usar TUDO — gravar vídeo, replay buffer, dizer "Raro" pra gravar, apertar botão de volume, ver galeria, comprar plano sandbox sem cobrar dinheiro de verdade. Em PT-BR por padrão, mas pode trocar pra ES ou EN nas Settings.

**O que você precisa pagar**: $99 Apple Developer Program (anual) + $25 Google Play Console (taxa única, lifetime). Sem isso, esta sprint não termina.

**O que precisa de você fora do código**: configurar produtos in-app em App Store Connect e Google Play Console (passo a passo aqui). Preparar privacy policy + screenshots do app (eu te ajudo com texto, você faz screenshots em Settings → Take Screenshot no iPhone). Convidar cliente por email.

**Tempo estimado**: pelo menos 6-8 sessões. Andoid é complexo (CameraX tem corner cases em Xiaomi/Samsung). TestFlight review demora 24h após upload. Play Store Internal Testing review também ~24h.

**Risco prático**: alto se o Android device não cooperar (memória já avisa que ultra-wide é unreliable por OEM). Médio pra TestFlight rejection (privacy policy + screenshots faltando é causa #1 de rejection). Baixo pra Google Play Internal Testing (review é menos rigoroso).

**O que NÃO acontece nesta sprint**: submeter pra App Store / Play Store **production** (release público). Isso é uma fase separada que vem DEPOIS de Sprint 3 — quando cliente aprova o testing e a gente faz polish final + screenshots oficiais + descrição + categoria + marketing.

