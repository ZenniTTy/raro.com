# Sprint 2 — Backend/Lógica Real iOS (Detailed Execution Plan)

> **REQUIRED SUB-SKILL** para sessões de execução: `superpowers:subagent-driven-development`. Tasks usam checkbox `- [ ]`.

**Goal**: Substituir implementações mock dos Riverpod providers de Sprint 1 por implementações REAIS, mantendo a mesma signature pública (UI não muda). Entregar app iOS funcionalmente completo no iPhone 12 (free Apple ID) — gravação real, replay buffer, wake word, volume button, paywall RevenueCat sandbox, vault persistido.

**Arquitetura**: Riverpod provider swap-in. Cada feature mantém o `presentation/` intacto (UI fiel ao prototype já entregue em Sprint 1) e troca a implementação interna do `application/<name>_provider.dart`. Pigeon channels novos onde precisar de native code.

**Tech Stack**: + `AVFoundation` (recording, replay buffer, volume KVO), `SFSpeechRecognizer` (wake word), `purchases_flutter ^10.1.1` (RevenueCat), `share_plus`, `path_provider`. Sem novas deps Flutter; novas APIs nativas Swift.

---

## Contexto

**Estado de entrada (depois de Sprint 1)**:
- `develop` contém merge de `feat/camera-native-bridge` + walking skeleton 12 telas
- Todos providers Sprint 1 têm signature real mas implementação hard-coded
- iPhone 12 free Apple ID ainda em uso (debug, rebuild 7-day refresh)
- CLAUDE.md atualizado pra estado real (§8 9 hooks, §11 critério-cortada, §15 roadmap 3-sprint)
- Memórias trimmed (≤25)

**Estado de saída (depois de Sprint 2)**:
- Gravação real → MP4 H.264/H.265 → vault em `path_provider` documents dir
- Replay buffer 15s/30s rodando em background quando camera ativa
- Wake word "Raro" liga REC quando pronunciado (com `SFSpeechRecognizer` + transcript matching loop)
- Volume button (qualquer +/-) liga REC quando pressionado (KVO `AVAudioSession.outputVolume`)
- Paywall mostra produtos reais do RevenueCat sandbox (mensal/anual), free trial 30d
- Gallery lê vídeos reais do vault
- Share via `share_plus` exporta MP4
- App ainda roda iOS-only no iPhone 12 free Apple ID

**Princípio**: NÃO mexer em UI a menos que o swap exija (e.g., paywall pode precisar update se RevenueCat retornar metadata diferente do mock).

---

## Pre-flight checklist (rodar no início da sessão)

- [ ] Sprint 1 concluído: Blueprint §11 mostra todas 12 telas Sprint 1 ✅
- [ ] Branch `develop` clean: `git status` clean, `git log develop --oneline | head -5` mostra merge da camera-native-bridge
- [ ] Free Apple ID ainda ativo (não pagou $99 ainda — confirmar com usuário)
- [ ] `flutter analyze` + `flutter test` em `apps/mobile/` → 0 issues / PASS
- [ ] iPhone 12 conectado (USB ou wireless pareado)
- [ ] **Apple Sandbox tester account criada**: App Store Connect → Users → Sandbox Testers. Criar `raro-sandbox@<seu-domínio>.test` com senha. Sign-out do AppleID real no iPhone 12 (Settings → App Store → sign out) e sign-in com o sandbox tester APENAS quando testar paywall. Sem isso, RevenueCat sandbox não funciona.
- [ ] Audit deste MD rodado por agente fresh (ver "Audit checklist" no final)

---

## Sprint Goals (observáveis binários)

- **G1 — Recording funcional**: tap REC grava vídeo MP4 em vault, gallery atualiza automaticamente, preview reproduz. Latência tap → started <300ms.
- **G2 — Replay buffer 15s/30s**: quando camera ativa, últimos N segundos sempre disponíveis em buffer; tap "Salvar replay" persiste como vídeo no vault.
- **G3 — Wake word "Raro" funcional**: dizer "Raro" enquanto app em foreground + camera ativa liga REC (latência detection → REC start ≤500ms).
- **G4 — Volume button funcional**: pressionar volume +/- liga ou para REC quando camera ativa.
- **G5 — Paywall RevenueCat sandbox funcional**: paywall mostra produtos reais do RevenueCat, free trial 30 dias rastreado, "Subscribe" funciona com sandbox account (não consume moeda real).
- **G6 — Vault + share funcional**: vídeos persistidos em `getApplicationDocumentsDirectory()/vault/`, listáveis em gallery, share via system sheet.
- **G7 — Lefthook GREEN**: todos commits Sprint 2 passam analyze + test + contract sem `--no-verify`.

---

## Sessões previstas

| # | Objetivo | Entregável | Files principais |
|---|---|---|---|
| **S2.A** ✅ | Recording + Vault | `.mov` grava, lista, reproduz **(DONE — sessão 0016, ADR-0018, device-validated; extra: thumbnail real sessão 0017/ADR-0019)** | `lib/features/camera/data/`, `ios/Runner/Native/Camera/RecordingPipeline.swift` + `ThumbnailGenerator.swift` |
| **S2.B** ◀ próximo | Replay buffer | Buffer 15s/30s ativo + salvar replay | `ios/Runner/Native/Camera/ReplayBuffer.swift`, ADR-0003 refresh |
| **S2.C** | Wake word "Raro" | Voz liga REC, sem falso positivo razoável | `ios/Runner/Native/Voice/WakeWordDetector.swift`, Pigeon `VoiceHostApi` |
| **S2.D** | Volume button trigger | Volume +/- toggla REC | `ios/Runner/Native/Volume/VolumeWatcher.swift`, Pigeon `VolumeHostApi` |
| **S2.E** | RevenueCat sandbox | Paywall real + trial 30d | `lib/features/paywall/data/revenuecat_repository.dart`, `lib/core/billing/` |
| **S2.F** | Share + Polish | Share via system sheet + bugs | `lib/features/preview/`, `lib/features/gallery/` |

---

## Tasks atômicas

> **Status (2026-06-04):** **Task A (S2.A) DONE** — sessões 0016 (recording+vault, ADR-0018) e 0017 (thumbnail real na galeria, ADR-0019), validadas no iPhone 12 físico. G1 (recording funcional) entregue, **exceto medição formal de latência tap→started <300ms** (validação perceptual feita; instrumentação pendente). Os checkboxes `[ ]` abaixo da Task A são o detalhe do plano original e não foram re-marcados individualmente — ver sessões 0016/0017 + CHANGELOG 0.6.0/0.6.1 para o que de fato entrou. **Próxima sessão: Task B (S2.B) — Replay buffer.** Branch `feat/camera-native-bridge` (PR #1 → develop aberto, NÃO mergeado; merge segurado pelos gates G1-latência/G7-perf/Android/goldens).

### Task A — Recording real + Vault (S2.A) ✅ DONE

#### A1. Pigeon API para start/stop recording

**Files**:
- Modify: `apps/mobile/pigeons/camera_api.dart` (adicionar HostApi methods)
- Will-regenerate: `apps/mobile/lib/core/native_bridges/camera_api.g.dart`
- Will-regenerate: `apps/mobile/ios/Runner/Native/Pigeon/CameraApi.g.swift`

**DONE criteria**: Pigeon regenera sem erros; `dart analyze` zero issues; Swift compila no Simulator.

- [ ] **Step 1**: Adicionar ao `camera_api.dart`:
  ```dart
  @HostApi()
  abstract class CameraHostApi {
    // existing methods kept...
    
    /// Start recording. Returns the recording session id.
    String startRecording(RecordingOptions options);
    
    /// Stop recording. Returns the path to the saved video.
    String stopRecording();
  }
  
  class RecordingOptions {
    RecordingOptions({required this.resolution, required this.fps, required this.codec});
    String resolution; // "1080p", "4K"...
    int fps; // 30, 60
    String codec; // "h264", "h265"
  }
  ```
- [ ] **Step 2**: Regenerar:
  ```bash
  bun --filter @raro/mobile run pigeon
  ```
- [ ] **Step 3**: Verificar geração em `.g.dart` e `.g.swift`.

#### A2. RecordingPipeline.swift implementação

**Files**:
- Create: `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift`
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` (integrar pipeline)
- Modify: `apps/mobile/ios/RunnerTests/CameraManagerRecordingTests.swift` (criar — TDD)

**DONE criteria**: XCTest passa cobrindo start → stop → MP4 existe; smoke test em iPhone 12 grava 3s e reproduz.

- [ ] **Step 1**: Test first em `CameraManagerRecordingTests.swift`:
  ```swift
  func testStartStopProducesFile() {
    let manager = CameraManager(/* deps */)
    manager.startRecording(options: ...)
    Thread.sleep(forTimeInterval: 2)
    let path = manager.stopRecording()
    XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    let attr = try? FileManager.default.attributesOfItem(atPath: path)
    XCTAssertGreaterThan(attr![.size] as! Int64, 1000) // > 1KB
  }
  ```
- [ ] **Step 2**: Rodar `bun --filter @raro/mobile run test:ios`. Esperado: FAIL.
- [ ] **Step 3**: Implementar `RecordingPipeline.swift` usando `AVCaptureMovieFileOutput`:
  ```swift
  import AVFoundation
  
  final class RecordingPipeline {
    private var movieOutput: AVCaptureMovieFileOutput?
    
    func attach(to session: AVCaptureSession) throws {
      let output = AVCaptureMovieFileOutput()
      guard session.canAddOutput(output) else {
        throw RecordingError.cannotAddOutput
      }
      session.addOutput(output)
      self.movieOutput = output
    }
    
    func start(toURL url: URL, codec: AVVideoCodecType, fps: Int32) throws {
      guard let output = movieOutput else { throw RecordingError.notAttached }
      // configurar codec + connection settings
      let conn = output.connection(with: .video)
      conn?.videoCodecType = codec
      output.startRecording(to: url, recordingDelegate: self)
    }
    
    func stop() -> URL? {
      movieOutput?.stopRecording()
      return movieOutput?.outputFileURL
    }
  }
  
  extension RecordingPipeline: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
      // log + notify delegate
    }
  }
  ```
- [ ] **Step 4**: Integrar em `CameraManager.swift`: novos métodos `startRecording(options)` e `stopRecording()` que delegam ao pipeline.
- [ ] **Step 5**: Conectar via Pigeon (Swift host implementation).
- [ ] **Step 6**: Rodar XCTest → PASS. Smoke manual no iPhone 12.
- [ ] **Step 7**: Commit: `feat(camera): real recording pipeline avcapture movieoutput + xctests`.

#### A3. Vault service (Dart side)

**Files**:
- Create: `apps/mobile/lib/features/camera/data/vault_service.dart`
- Create: `apps/mobile/lib/features/camera/data/vault_service_provider.dart` (codegen)
- Modify: `apps/mobile/lib/features/gallery/application/video_list_provider.dart` (swap implementation)
- Create: `apps/mobile/test/features/camera/vault_service_test.dart`

**DONE criteria**: vault_service salva arquivo, lista arquivos, video_list_provider retorna vídeos reais do vault.

- [ ] **Step 1**: Test first:
  ```dart
  test('VaultService.save persists file and listAll returns it', () async {
    final service = VaultService(documentsDir: tempDir);
    final saved = await service.save(sourceFile, metadata: ...);
    final all = await service.listAll();
    expect(all.length, 1);
    expect(all.first.path, saved.path);
  });
  ```
- [ ] **Step 2**: Implementar:
  ```dart
  class VaultService {
    final Directory documentsDir;
    
    VaultService({required this.documentsDir});
    
    Future<VideoEntity> save(File source, {required RecordingMetadata metadata}) async {
      final vaultDir = Directory('${documentsDir.path}/vault');
      await vaultDir.create(recursive: true);
      final dest = File('${vaultDir.path}/${metadata.id}.mp4');
      await source.copy(dest.path);
      // gerar thumbnail via video_thumbnail package?
      return VideoEntity(
        id: metadata.id,
        name: metadata.name,
        length: metadata.length,
        recordedAt: metadata.recordedAt,
        isReplay: metadata.isReplay,
        thumbnailPath: ..., // generated
      );
    }
    
    Future<List<VideoEntity>> listAll() async {
      final vaultDir = Directory('${documentsDir.path}/vault');
      if (!vaultDir.existsSync()) return [];
      final files = vaultDir.listSync().whereType<File>().where((f) => f.path.endsWith('.mp4'));
      return files.map(_metadataFor).toList();
    }
    
    VideoEntity _metadataFor(File file) { /* parse filename + stat */ }
  }
  ```
- [ ] **Step 3**: Swap em `video_list_provider.dart`:
  ```dart
  @riverpod
  Future<List<VideoEntity>> videoList(VideoListRef ref) async {
    final vault = await ref.read(vaultServiceProvider.future);
    return vault.listAll();
  }
  ```
  Sprint 1 mocks ficam apenas em test fixtures.
- [ ] **Step 4**: Commit: `feat(vault): vault_service + swap video_list_provider para vault real`.

#### A4. Integrar recording → vault → gallery

**Files**:
- Modify: `apps/mobile/lib/features/camera/application/recording_state_provider.dart`

**DONE criteria**: tap REC chama bridge real, stop salva no vault, gallery atualiza via auto-invalidate.

- [ ] **Step 1**: Swap implementation:
  ```dart
  @riverpod
  class RecordingState extends _$RecordingState {
    @override
    Recording build() => const Recording.idle();
    
    Future<void> toggle() async {
      if (state is RecordingIdle) {
        final api = ref.read(cameraHostApiProvider);
        final settings = await ref.read(settingsProvider.future);
        final id = await api.startRecording(RecordingOptions(...));
        state = Recording.active(id: id, startedAt: DateTime.now());
      } else if (state is RecordingActive) {
        final api = ref.read(cameraHostApiProvider);
        final path = await api.stopRecording();
        final vault = await ref.read(vaultServiceProvider.future);
        await vault.save(File(path), metadata: ...);
        ref.invalidate(videoListProvider); // gallery refresh
        state = const Recording.idle();
      }
    }
  }
  ```
- [ ] **Step 2**: Smoke test no iPhone 12: tap REC → 3s → tap REC → vídeo aparece em Gallery → tap thumbnail → reproduz.
- [ ] **Step 3**: Commit: `feat(camera): wire recording -> vault -> gallery via providers`.

---

### Task B — Replay buffer 15s/30s (S2.B)

#### B1. ADR-0003 refresh (replay buffer strategy)

**Files**: `docs/decisions/0003-replay-buffer-native.md` (existe — atualizar implementation section).

**DONE criteria**: ADR descreve estratégia escolhida (`AVAssetWriter` + circular dispatch + `CVPixelBufferPool`).

- [ ] **Step 1**: Ler ADR-0003 atual.
- [ ] **Step 2**: Atualizar seção "Implementation" com decisão final:
  - Usar `AVAssetWriter` com `mediaType: .video` + `expectsMediaDataInRealTime: true`
  - Dispatch queue dedicada serial
  - Buffer circular: 2 `AVAssetWriter` rotativos, cada um cobrindo metade da janela (15s ou 30s)
  - Quando tap "Save replay" recebido: flush writer ativo + concat com writer anterior + escrever no vault
  - Reciclar `CVPixelBuffer` via pool (memória `raro-pattern-ios-cvpixelbufferpool`)
- [ ] **Step 3**: Commit (com Task B2 batch).

#### B2. ReplayBuffer.swift implementação

**Files**:
- Create: `apps/mobile/ios/Runner/Native/Camera/ReplayBuffer.swift`
- Create: `apps/mobile/ios/RunnerTests/ReplayBufferTests.swift`
- Modify: `apps/mobile/pigeons/camera_api.dart` (adicionar `enableReplayBuffer`, `saveReplay`)
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` (wire pipeline)

**DONE criteria**: XCTest valida que após 30s de captura, `saveReplay()` produz MP4 com ~30s do trailing window.

- [ ] **Step 1**: Pigeon methods:
  ```dart
  void enableReplayBuffer(int seconds); // 15 ou 30
  void disableReplayBuffer();
  String saveReplay();
  ```
- [ ] **Step 2**: ReplayBuffer.swift (esqueleto):
  ```swift
  final class ReplayBuffer {
    private let bufferSeconds: Int
    private var primaryWriter: AVAssetWriter?
    private var secondaryWriter: AVAssetWriter?
    // ...
    
    func append(sampleBuffer: CMSampleBuffer) {
      // rotate writers se ativo cruzou metade da janela
      activeWriter?.append(sampleBuffer)
    }
    
    func save() throws -> URL {
      // finalize ambos writers, concat se possível, retornar URL
    }
  }
  ```
- [ ] **Step 3**: XCTest cobrindo: encher buffer com sample buffers fake por 30s, chamar save, verificar arquivo MP4 com duração próxima de 30s.
- [ ] **Step 4**: Integrar em `CameraManager.swift`: quando `enableReplayBuffer(seconds)` chamado, attach data output → ReplayBuffer.
- [ ] **Step 5**: Smoke test no iPhone 12: ligar camera → esperar 30s → "Save replay" UI → ver MP4 em Gallery contendo últimos 30s.
- [ ] **Step 6**: Commit: `feat(replay): replay buffer nativo avassetwriter circular + xctests`.

#### B3. Wire Dart side

**Files**:
- Create: `apps/mobile/lib/features/replay/application/replay_buffer_provider.dart`
- Modify: `apps/mobile/lib/features/camera/presentation/widgets/buffer_pill.dart` (já existe Sprint 1 — agora liga ao provider real)

**DONE criteria**: buffer pill toggle 15s/30s liga/desliga buffer nativo; botão "Save replay" persiste vídeo.

- [ ] Commit: `feat(replay): wire replay buffer provider + buffer_pill liga ao native bridge`.

---

### Task C — Wake word "Raro" (S2.C)

#### C1. Memória relevante: `raro-pattern-ios-wake-word-no-native-api`

Confirmar que memória continua exata (1000 req/h `SFSpeechRecognizer`, 1min/sessão, restart loop).

#### C2. Pigeon VoiceHostApi

**Files**:
- Create: `apps/mobile/pigeons/voice_api.dart`
- Regenerar `.g.dart` + `.g.swift`.

```dart
@HostApi()
abstract class VoiceHostApi {
  void startListening(); // inicia loop de detecção
  void stopListening();
}

@FlutterApi()
abstract class VoiceFlutterApi {
  void onWakeWordDetected(); // bridge → Flutter
}
```

#### C3. WakeWordDetector.swift

**Files**:
- Create: `apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift`
- Create: `apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift`
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift` (registrar VoiceHostApi)

**DONE criteria**: detector dispara `onWakeWordDetected` quando transcript contém "Raro" (case-insensitive); restart loop a cada 50s pra evitar timeout.

- [ ] **Step 1**: Implementação esqueleto:
  ```swift
  final class WakeWordDetector: NSObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))!
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var restartTimer: Timer?
    
    func start() {
      // SFSpeechRecognizer.requestAuthorization
      // setup audio engine + tap input bus
      // schedule restart timer a cada 50s
    }
    
    func stop() {
      restartTimer?.invalidate()
      audioEngine.stop()
      recognitionTask?.cancel()
    }
    
    private func handleTranscript(_ transcript: String) {
      if transcript.lowercased().contains("raro") {
        VoiceFlutterApi.shared?.onWakeWordDetected()
        // ignorar próximas detecções por 2s pra evitar burst
      }
    }
  }
  ```
- [ ] **Step 2**: XCTest com fake transcript → assert `onWakeWordDetected` chamado.
- [ ] **Step 3**: Smoke test iPhone 12: abrir camera → dizer "Raro" → REC inicia.
- [ ] **Step 4**: Commit: `feat(voice): wake word raro detector sfspeechrecognizer + restart loop 50s`.

#### C4. Wire Dart side

**Files**:
- Create: `apps/mobile/lib/features/voice/application/wake_word_provider.dart`
- Modify: `apps/mobile/lib/features/camera/application/recording_state_provider.dart` (subscribe to wake word stream)

**DONE criteria**: provider expõe stream<WakeWordEvent>, recording_state_provider chama `toggle()` ao receber evento.

#### C5. Toggle wake word via settings

**Files**:
- Modify: `apps/mobile/lib/features/settings/presentation/settings_screen.dart` (already has control mode setting)
- Modify: `apps/mobile/lib/features/voice/application/wake_word_provider.dart` (start/stop baseado em settings.controlMode == voice)

- [ ] Commit: `feat(voice): subscribe wake word event → recording state + on/off via settings.controlMode`.

---

### Task D — Volume button trigger (S2.D)

#### D1. Memória relevante: `raro-pattern-ios-volume-button-kvo-app-store-review`

Confirmar:
- AVAudioSession category `.ambient` (não duck)
- restore initialVolume após callback
- removeObserver no deinit
- App Store review aceita uso pra captura de mídia

#### D2. Pigeon VolumeHostApi + FlutterApi

**Files**:
- Create: `apps/mobile/pigeons/volume_api.dart`
- Regenerar.

```dart
@HostApi()
abstract class VolumeHostApi {
  void startWatching();
  void stopWatching();
}

@FlutterApi()
abstract class VolumeFlutterApi {
  void onVolumePressed(String direction); // "up" or "down"
}
```

#### D3. VolumeWatcher.swift

**Files**:
- Create: `apps/mobile/ios/Runner/Native/Volume/VolumeWatcher.swift`
- Create: `apps/mobile/ios/RunnerTests/VolumeWatcherTests.swift`

**DONE criteria**: KVO em `AVAudioSession.sharedInstance().outputVolume`; quando muda, restaurar pro valor inicial + emitir evento.

- [ ] **Step 1**: Implementação:
  ```swift
  final class VolumeWatcher: NSObject {
    private var initialVolume: Float = 0.5
    private var isWatching = false
    
    func start() {
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.ambient)
      try? session.setActive(true)
      initialVolume = session.outputVolume
      session.addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
      isWatching = true
    }
    
    func stop() {
      guard isWatching else { return }
      AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
      isWatching = false
    }
    
    override func observeValue(forKeyPath: ..., of: ..., change: ..., context: ...) {
      guard let new = change?[.newKey] as? Float else { return }
      let direction = new > initialVolume ? "up" : "down"
      // restaurar
      MPVolumeView.setVolume(initialVolume)
      VolumeFlutterApi.shared?.onVolumePressed(direction: direction)
    }
    
    deinit { stop() }
  }
  ```
- [ ] **Step 2**: XCTest com fake KVO change.
- [ ] **Step 3**: Smoke test iPhone 12: abrir camera → pressionar volume up → REC inicia → volume down → REC para.
- [ ] **Step 4**: Commit: `feat(volume): volume button watcher kvo avaudiosession ambient + restore`.

#### D4. Wire Dart side

**Files**:
- Create: `apps/mobile/lib/features/volume/application/volume_button_provider.dart`
- Modify: `apps/mobile/lib/features/camera/application/recording_state_provider.dart` (subscribe)

- [ ] Commit: `feat(volume): subscribe volume event → recording state + on/off via settings.controlMode`.

---

### Task E — RevenueCat sandbox paywall (S2.E)

#### E1. Memória relevante: `raro-pattern-revenuecat-trial-app-store-connect` + `raro-pattern-revenuecat-error-handling`

Re-leitura obrigatória antes de tocar código. Trial 30d configurado em App Store Connect, NÃO em código. SDK só APLICA.

#### E2. App Store Connect setup (pré-código)

**Files**: nenhum (config externa).

**DONE criteria**: 2 produtos sandbox criados em App Store Connect — `com.rarocamera.monthly` (R$ 9,90, free trial 30d) e `com.rarocamera.yearly` (R$ 89,90, free trial 30d).

- [ ] **Step 1**: Usuário entra em App Store Connect (free Apple ID **NÃO BASTA** pra criar produtos — precisa Apple Dev pago OU usar workaround: definir produtos via RevenueCat Web UI apenas, sem create no App Store Connect pra Sprint 2). 
- [ ] **Step 2 (alternativa Sprint 2 sem $99)**: configurar produtos no RevenueCat Web dashboard apontando pra App Store Connect product IDs mesmo sem criar lá. SDK em sandbox mode vai retornar metadata mockado da config web. Funcional pra dev iOS sem Apple Dev pago.
- [ ] **Step 3**: Criar RevenueCat API key (free tier RevenueCat permite até $10K/mês de vendas — para Sprint 2 sandbox é gratuito).

#### E3. RevenueCat Flutter integration

**Files**:
- Create: `apps/mobile/lib/core/billing/revenuecat_initializer.dart`
- Create: `apps/mobile/lib/features/paywall/data/revenuecat_repository.dart`
- Modify: `apps/mobile/lib/features/paywall/application/subscription_status_provider.dart` (swap implementation)
- Create: `apps/mobile/test/features/paywall/revenuecat_repository_test.dart`

**DONE criteria**: paywall lista produtos reais; tap "Subscribe" no sandbox account inicia trial; subscription_status_provider reflete estado real.

- [ ] **Step 1**: Inicializar SDK em `app.dart` ou `main.dart`:
  ```dart
  await Purchases.configure(PurchasesConfiguration('appl_xxxxx'));
  ```
- [ ] **Step 2**: Repository:
  ```dart
  class RevenueCatRepository {
    Future<List<Package>> getOfferings() async {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    }
    
    Future<bool> purchase(Package package) async {
      try {
        final result = await Purchases.purchasePackage(package);
        return result.customerInfo.entitlements.active.containsKey('pro');
      } on PlatformException catch (e) {
        // memória: usar PurchasesErrorHelper.getErrorCode pra type-safe handling
        final code = PurchasesErrorHelper.getErrorCode(e);
        if (code == PurchasesErrorCode.purchaseCancelledError) return false;
        rethrow;
      }
    }
  }
  ```
- [ ] **Step 3**: Swap `subscription_status_provider`:
  ```dart
  @riverpod
  Future<SubscriptionState> subscriptionStatus(...) async {
    final info = await Purchases.getCustomerInfo();
    final active = info.entitlements.active['pro'];
    return SubscriptionState(
      isSubscribed: active != null,
      trialEndsAt: active?.expirationDate,
      // ...
    );
  }
  ```
- [ ] **Step 4**: Smoke test iPhone 12 com sandbox tester signed in: paywall mostra produtos → tap "Mensal" → tap "Subscribe" → confirm sandbox dialog → app retorna com `isSubscribed=true` + trial 30d countdown.
- [ ] **Step 5**: Commit: `feat(paywall): revenuecat sandbox integration + swap subscription provider`.

---

### Task F — Share + Polish (S2.F)

#### F1. Share via share_plus

**Files**:
- Modify: `apps/mobile/lib/features/preview/presentation/preview_screen.dart` (botão share habilitado)
- Modify: `apps/mobile/lib/features/preview/application/share_provider.dart` (criar)

**DONE criteria**: tap share em preview abre system share sheet com MP4 anexado.

- [ ] **Step 1**: Implementar:
  ```dart
  @riverpod
  class ShareController extends _$ShareController {
    @override
    void build() {}
    
    Future<void> shareVideo(VideoEntity video) async {
      await Share.shareXFiles([XFile(video.path)], text: video.name);
    }
  }
  ```
- [ ] **Step 2**: Smoke test: tap share → AirDrop/Mail/etc. aparece com MP4 attached.
- [ ] **Step 3**: Commit: `feat(preview): share via share_plus + xfile`.

#### F2. Delete video

**Files**:
- Modify: `lib/features/preview/presentation/preview_screen.dart` (trash button habilitado)
- Modify: `lib/features/camera/data/vault_service.dart` (adicionar delete method)

- [ ] Commit: `feat(preview): delete via vault_service + auto-refresh gallery`.

#### F3. Trial countdown UI

**Files**:
- Modify: `lib/features/paywall/presentation/widgets/trial_countdown.dart`

**DONE criteria**: widget mostra "X dias restantes" baseado em subscriptionStatus.trialEndsAt.

#### F4. Validação Sprint 2 fim-a-fim

**DONE criteria**: smoke test completo no iPhone 12:
- Tap REC → grava 10s → tap REC → MP4 em Gallery
- Replay buffer ligado → após 30s, tap "Salvar replay" → MP4 em Gallery contendo últimos 30s
- Dizer "Raro" → REC inicia
- Pressionar volume up → REC inicia
- Paywall → Subscribe sandbox → trial countdown rodando
- Share via preview → system sheet abre

- [ ] Atualizar Blueprint §11 marcando Sprint 2 checkboxes ✅.
- [ ] Session log + INDEX update.
- [ ] Commit final: `docs(sprint-2): blueprint checkboxes + session log closure`.

---

## Riscos conhecidos

| Risco | Mitigação |
|---|---|
| `SFSpeechRecognizer` quota 1000 req/h excedida em testes | Restart loop 50s mantém abaixo do limite. Smoke test não exercita >10 detections/h. |
| Wake word falso positivo ("rato", "raro" em outras palavras) | Transcript match exato (regex `\braro\b`). Memória aplicável. |
| Volume KVO app store review rejection | Memória diz aceito pra captura mídia. Documentar uso em Info.plist `NSAppleEventsUsageDescription`. |
| Replay buffer memory pressure no iPhone 12 (4GB RAM) | `CVPixelBufferPool` recicla. Limitar buffer a 30s @ 1080p30 = ~150MB de raw frames. Usar codec H.264 com `expectsMediaDataInRealTime` true mantém footprint baixo. |
| RevenueCat sandbox requer Apple Dev pago | Workaround: config produtos só no RevenueCat Web dashboard, SDK mode sandbox sem App Store Connect product creation. Pode ser que precise pagar $99 prematuramente se workaround não funcionar. Validar EARLY em Task E2. |
| Recording produz MP4 corrompido por bug native | XCTest valida tamanho > 1KB; smoke test valida reprodução em preview. |
| Vault enche disco do iPhone | Adicionar warning quando vault > 500MB. Task F polish. |
| Wake word + REC mesma tela → audio capture conflict | `AVAudioSession.ambient` permite mix. Validar em smoke test. |
| Volume button durante gravação muda volume sem disparar callback | KVO em `outputVolume` cobre. Smoke test confirma. |

---

## Out of scope (vira Sprint 3)

- ✗ Android (qualquer parte)
- ✗ TestFlight build / Apple Developer Program $99
- ✗ Google Play Console / Internal Testing
- ✗ i18n PT/ES/EN
- ✗ Crashlytics breadcrumbs real (já configurado em Sprint 0, mas events Sprint 3)
- ✗ Analytics events Firebase (eventos definidos em ADR-0013, implementação Sprint 3)
- ✗ P12 Xiaomi modal (Sprint 3 Android)
- ✗ P13 Bluetooth modal (Sprint 3)
- ✗ P14 Lock mode (Sprint 3)
- ✗ Performance gates: golden tests + integration_test E2E (Sprint 3)

---

## Audit checklist (rodar no início da sessão de execução Sprint 2)

Cole pra agente fresh:

> Audite `docs/superpowers/plans/sprint-2-backend-logic-ios.md` contra:
> 1. Sprint 1 está completo? Blueprint §11 todos checkboxes Sprint 1 ✅?
> 2. Tasks A-F: file paths são válidos? Pigeon API methods sintáticos? Swift APIs existem em iOS 15+?
> 3. Memórias referenciadas (`raro-pattern-ios-wake-word-no-native-api`, `raro-pattern-revenuecat-trial-app-store-connect`, `raro-pattern-revenuecat-error-handling`, `raro-pattern-ios-volume-button-kvo-app-store-review`, `raro-pattern-ios-cvpixelbufferpool`) existem em `~/.claude/projects/.../memory/`?
> 4. ADR-0003 (replay buffer), ADR-0010 (dual subscription), ADR-0011 (volume) existem em `docs/decisions/`?
> 5. RevenueCat workaround Task E2 sem Apple Dev pago é factível? Pesquisar via WebSearch + Context7.
> 6. Wake word + REC mesma tela conflito audio é tratável com `AVAudioSession.ambient`?
> 7. Goals G1-G7 binários e mensuráveis?
> 8. Placeholders TBD/TODO/"implement later" em alguma task?
>
> Report em ≤400 palavras. Se 0 holes, dizer "Audit clean, pode executar Task A1".

Se ≥1 hole, corrigir antes de A1.

---

## Em palavras simples

**O que Sprint 2 entrega**: o app vira REAL. Você grava vídeo de verdade, abre a galeria e vê o vídeo, dá play. Diz "Raro" e a câmera começa a gravar sozinha. Aperta o botão de volume e idem. Vai pro paywall, "compra" o plano em modo sandbox da Apple (sem cobrar de verdade) e o app aceita a assinatura. Pode também compartilhar o vídeo via WhatsApp/iMessage/AirDrop direto do app.

**O que você precisa fazer fora do código**: criar uma conta Sandbox Tester no App Store Connect (gratuito, mesmo sem $99 Apple Dev). E sair do seu Apple ID real no iPhone só quando for testar paywall, voltando depois (sandbox tester só serve pra teste de pagamento).

**Tempo estimado**: pelo menos 4-6 sessões. Cada parte (recording, replay buffer, wake word, volume, paywall, share) tem suas armadilhas de iOS nativo. A audit no início de cada sessão vai pegar onde o plano falhou.

**Risco prático**: médio. Tudo aqui já tem memória escrita do que pode dar errado. O ponto mais arriscado é wake word "Raro" — `SFSpeechRecognizer` tem quota e timeout que exigem restart loop, e falso positivo pode dar agonia se for muito sensível. Por isso o gate de smoke test "dizer 'Raro' 5x → REC inicia 5x" é importante.

**O que NÃO acontece nesta Sprint**: nada de Android, nada de pagar Apple $99, nada de TestFlight. Tudo isso vira Sprint 3.

