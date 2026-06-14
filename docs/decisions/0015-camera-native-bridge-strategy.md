# 0015 — Camera native bridge strategy

- **Data:** 2026-05-26
- **Status:** Accepted
- **Spec:** docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
- **Supersedes:** —
- **Decisores:** Eduardo Rodrigues (Elovision)

## Contexto

Briefing Seção 6.2 e Blueprint Seção 2.2 exigem implementação 100% nativa da câmera (plugin oficial `camera` não suporta alternância 0.5×/1×, issues flutter#91247 + #173406). Esta é a primeira spec do Roadmap rm-7 (bridges nativos), valida o pipeline ponta-a-ponta antes de evoluir para replay_buffer/voice/volume.

## Decisão

1. **Pigeon-first contract**. Todas as ops `@async`. Enums tipados (`LensType`, `Resolution`, `Fps`). FlutterApi para callbacks. Sub-package Kotlin `com.rarocamera.raro_mobile.generated.camera` (ADR-0013 anti-redeclaration).
2. **iOS — VirtualCameraStrategy única.** `builtInTripleCamera` → `builtInDualWideCamera` + `videoZoomFactor` (smooth zoom). YAGNI: iPhones com 0.5× sempre expõem virtual camera. `SwapInputStrategy` documentada como rollback acionável via ADR-update se device test futuro revelar exceção. **→ Refinado por [ADR-0021](0021-4k60-physical-lens-vs-virtual-zoom.md) (sessão 0019):** o device test revelou a exceção prevista — 4K@60 só existe na lente física (`builtInWideAngleCamera`), não no device virtual. A VirtualCameraStrategy segue o **default** (zoom contínuo); 4K60 é opt-in que aciona a lente física (a `SwapInputStrategy` aqui prevista).
3. **Android — CameraX 1.6.1** pinado (latest stable em 2026-05-26, novo motor CameraPipe). Device test obrigatório em Xiaomi/Samsung antes de RC.
4. **Android PlatformView — hybrid composition.** Necessário para HUD Flutter sobre preview. Custo GPU 5-10% aceito.
5. **iOS format control via `activeFormat`** + `activeVideoMinFrameDuration`/`MaxFrameDuration`. `sessionPreset` insuficiente para garantir 4K@60.
6. **Threading**: HostApi main thread por default; ops pesadas (discovery, format negotiation) via `makeBackgroundTaskQueue()` iOS / Looper main Android. Callbacks Flutter sempre na main thread.
7. **Sem gravação** nesta ADR — boundary explícito com replay_buffer.
8. **Telemetria via camada Flutter apenas.** Bridge nativa não chama Firebase direto. Eventos canônicos em `AnalyticsEvents` (extensão de `api-contract-shared`): `cameraStarted`, `cameraStopped`, `cameraFocusTapped`, `cameraPermissionDenied`, `cameraError` + reuso de `lensSwitched`, `resolutionChanged`, `fpsChanged`.

## Consequências

**Positivas:**
- Bridge testável isoladamente sem replay_buffer
- Strategy única iOS reduz código e teste
- CameraX latest alinha com Blueprint
- Boundary com Firebase preserva testabilidade da bridge

**Negativas:**
- CameraX 1.6 CameraPipe novo — risco de regression em OEMs (mitigado por device test)
- Hybrid composition Android tem custo GPU
- Smooth zoom em virtual camera pode dropar framerate momentâneo (mitigado por device test + rollback documentado)

**Como reverter:** novo ADR substituindo, com revert dos commits desta spec.

## Alternativas consideradas

- Plugin oficial `camera` — rejeitado (briefing 6.2)
- `iris_camera` v1.0.5 — rejeitado (briefing 6.2: baixa adoção)
- `AVCaptureMultiCamSession` — rejeitado (overkill para alternância discreta)
- CameraX 1.5.x — rejeitado (Blueprint pede latest)
- Texture layer Android — rejeitado (HUD precisa overlay)
- 2 strategies iOS (Virtual + Swap) — rejeitado (YAGNI confirmado por matriz hardware)

## Referências

- Spec: docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
- ADRs predecessores: 0013, 0014
- Apple AVFoundation Capture Setup: https://developer.apple.com/documentation/avfoundation/capture_setup/choosing_a_capture_device
- CameraX docs: https://developer.android.com/media/camera/camerax
- CameraX releases: https://developer.android.com/jetpack/androidx/releases/camera
- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels
- Issues: flutter/flutter#91247, flutter/flutter#173406

## Addendum 2026-05-26 (post-audit Tasks 1-10)

Aprendizados aplicados após auditoria das Tasks 1-10:

1. **PlatformView é o único preview path para v1.0.** O parâmetro `textureId` em `CameraHostApi.startSession(int, CameraConfig)` é aceito mas ignorado pelo iOS (e será ignorado pelo Android). Mantido no schema para permitir migração futura para Texture-based preview sem breaking change no contract Pigeon. Documentado aqui em vez de remover do schema porque (a) remover requer re-codegen + atualizar testes existentes, (b) reservar é mais barato que reintroduzir.

2. **Threading refinado.** A regra original dizia "ops pesadas vão pra background queue". Na prática:
   - `discoverCapabilities()` e `switchLens()` são **leves** (enumera devices + 1 input swap) → aceitos na main thread.
   - `startSession.startRunning()` e `stopSession.stopRunning()` continuam em `sessionQueue` background (são síncronos pesados em AVFoundation).
   - Callbacks Flutter sempre via `DispatchQueue.main.async`.

3. **Erros tipados nunca devem perder semântica via `rawValue.description`.** O pattern correto ao emitir `PigeonError` é usar `"\(code)"` (nome simbólico) ou rotear via `CameraFlutterApi.onError(code:message:)` (callback tipado). Anti-pattern proibido por hook `block-pigeon-error-rawvalue.sh` registrado em `.claude/settings.json`.

4. **Tests pinning behavior, não apenas tipo.** TDD requer que cada branch da implementação tenha pelo menos 1 teste que **falha** se aquela branch for removida. `expect(x, isA<T>())` sem assertions de campo é insuficiente para spec coverage. Aplicado retroativamente nos testes do CameraController.

## Addendum 2026-05-27 (Flutter 3.44 SPM iOS 13 hardcoded fix)

Durante validação device no iPhone 12 do usuário, build Xcode quebrou repetidamente com 3 erros:

```
The package product 'firebase-crashlytics' requires minimum platform version 15.0 ... but this target supports 13.0
The package product 'firebase-core' requires minimum platform version 15.0 ...
The package product 'firebase-analytics' requires minimum platform version 15.0 ...
```

**Root cause confirmada via leitura do source do Flutter Tool** em `/usr/local/share/flutter/packages/flutter_tools/lib/src/darwin/darwin.dart:71`:

```dart
Version deploymentTarget() {
  return switch (this) {
    ios => Version(13, 0, null),   // ← hardcoded
    macos => Version(10, 15, null),
  };
}
```

O Flutter regera `apps/mobile/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` com `.iOS("13.0")` em **toda execução** de `flutter pub get`, `flutter run`, `flutter build ios` ou build via Xcode (que invoca `xcode_backend.sh build` internamente). `IPHONEOS_DEPLOYMENT_TARGET = 15.0` no `project.pbxproj` é ignorado por esse caminho.

Issue Flutter aberta: [flutter/flutter#176313](https://github.com/flutter/flutter/issues/176313), [#185039](https://github.com/flutter/flutter/issues/185039). Sem fix upstream em 2026-05.

### Decisão: Scheme Pre-action (workaround oficial Flutter)

Tentativa inicial via **Build Phase** (`CA00000000000000000000C1`) FALHOU porque Xcode resolve dependências SPM **ANTES** de qualquer Build Phase rodar. Os erros "package product requires minimum platform 15" são gerados na fase **"Resolve Package Graph"** que precede o pipeline de build phases.

**Solução correta (Flutter docs oficial 2026)**: adicionar uma `<ExecutionAction>` como Pre-action no `Runner.xcscheme`. Pre-actions rodam **antes** da resolução de pacotes.

`apps/mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` recebe segunda Pre-action após a oficial do Flutter:

```xml
<PreActions>
   <ExecutionAction title="Run Prepare Flutter Framework Script">
      "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" prepare
   </ExecutionAction>
   <ExecutionAction title="Fix SPM iOS Target (workaround flutter/flutter#162072)">
      "${SRCROOT}/../scripts/fix-spm-ios-target.sh"
   </ExecutionAction>
</PreActions>
```

Script: `apps/mobile/scripts/fix-spm-ios-target.sh` (idempotente).

**Por que não outras opções:**
- ❌ Editar Package.swift manualmente — Flutter regera, reverte em todo build
- ❌ Patch SDK Flutter (`darwin.dart`) — quebra a cada upgrade, afeta outros projetos
- ❌ Rodar script manualmente antes de `flutter run` — frágil; build pelo Play button do Xcode ignora
- ❌ **Build Phase** (tentativa inicial) — Build Phases rodam DEPOIS de SPM resolution; erro já aconteceu
- ✅ **Scheme Pre-action** — roda ANTES da resolução SPM, na ordem correta. Persistido em `xcshareddata` (commitado, compartilhado entre devs)

### Quando remover

Quando issue #176313 fechar e Flutter passar a respeitar `IPHONEOS_DEPLOYMENT_TARGET` do pbxproj ao gerar SPM. Validar:

```bash
rm -f apps/mobile/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
cd apps/mobile && flutter pub get
grep 'iOS(' apps/mobile/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
# Se .iOS("15.0") ou maior → remover Build Phase + script
```

### Memória persistente

`raro-pattern-flutter-spm-ios-13-hardcoded` registrada para que sessões futuras saibam disso de cara.

---

## Addendum 2026-05-28 — Lições da validação em device físico (iPhone 12)

Após implementação completa das tasks 1-18, a validação em device físico (iPhone 12) na task 19 revelou múltiplos gaps entre o design original da spec e o comportamento real do hardware iOS. Estes addenda documentam as descobertas que devem informar revisões futuras de specs de bridge nativo:

### A. iPhone DualWide Camera: minAvailableVideoZoomFactor reporta 1.0, não 0.5

A spec assumia que `device.minAvailableVideoZoomFactor` retornaria `0.5` em `builtInDualWideCamera` (que contém ultra-wide física dentro). **Não retorna.** O sistema reporta o mínimo da lente atualmente ativa (wide), não o mínimo absoluto do sistema.

**Mapping correto:**
- `LensType.ultraWide` → `videoZoomFactor = device.minAvailableVideoZoomFactor` (= 1.0 — sistema usa ultra-wide internamente)
- `LensType.wide` → `videoZoomFactor = device.virtualDeviceSwitchOverVideoZoomFactors.first` (= 2.0 no iPhone 12 — cruza switchover para wide)

Implementação consolidada em `CameraManager.applyVirtualLensZoom`. Sem blackout perceptível (G3 ✅).

Devices sem virtual device (iPhone SE 1ª gen, single-wide): fallback para `replace-input` entre `builtInUltraWideCamera` e `builtInWideAngleCamera`. **Blackout ~100-300ms inerente** — não há workaround sem AVCaptureMultiCamSession (overkill para v1.0).

### B. setFormat requer sessionPreset = .inputPriority

A spec não destacava este requisito Apple. Sem ele, `device.activeFormat` é silenciosamente sobrescrito pelo session preset default.

```swift
session.beginConfiguration()
session.sessionPreset = .inputPriority    // ESSENCIAL
try device.lockForConfiguration()
device.activeFormat = chosenFormat
device.unlockForConfiguration()
session.commitConfiguration()
```

Documentado em [developer.apple.com/forums/thread/664978](https://developer.apple.com/forums/thread/664978).

### C. Background/foreground requer notification observers

Sem `wasInterruptedNotification`/`interruptionEndedNotification`/`runtimeErrorNotification`, o app crash quando volta de Settings.app ou multitasking porque a session AVCapture fica em estado inválido após pause iOS. Auto-restart em `.mediaServicesWereReset` é obrigatório (cleanup-recovery padrão Apple).

### D. permission_handler Flutter exige macros no Podfile

**Bug invisível mais grave da spec.** O `permission_handler ^12.0.1` declarado no `pubspec.yaml` + `NSCameraUsageDescription` no `Info.plist` + código Dart correto **não são suficientes** se o `Podfile` não definir os macros `GCC_PREPROCESSOR_DEFINITIONS` apropriados:

```ruby
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
  '$(inherited)',
  'PERMISSION_CAMERA=1',
  'PERMISSION_MICROPHONE=1',
  'PERMISSION_PHOTOS=1',
  'PERMISSION_SPEECH_RECOGNIZER=1',
]
```

Sem isso, `Permission.camera.request()` retorna `denied` **sintético**, sem chamar `AVCaptureDevice.requestAccess`. Resultado: iOS nunca registra o app como camera-user e Câmera **nunca aparece em Ajustes → App**.

Best practice documentada em [pub.dev/packages/permission_handler#setup-ios](https://pub.dev/packages/permission_handler) — não foi seguida no scaffold inicial (Fase 2). Adicionada na task 19 de validação.

**Frágil:** o Podfile RARO é gitignored (decisão ADR-0014, Flutter 3.44 regenera para plugins não-SPM). Para garantir persistência, foi criado `scripts/bootstrap-ios-permissions.sh` que reaplica os macros após cada `flutter pub get`. Adicionado ao wrapper `bun --filter @raro/mobile run pub:get`.

### E. AVFoundation Sendable warnings (Swift 6)

Build em strict concurrency mode emite warnings sobre `AVCaptureSession` não ser `Sendable`. Workaround oficial (forums.swift.org): `@preconcurrency import AVFoundation` + `@unchecked Sendable` em classes que retêm session em closures `@Sendable`. Aceitável até Apple adicionar Sendable conformance ao AVFoundation.

### F. FigCaptureSourceRemote err=-17281

Ruído iOS 26 benigno confirmado por Apple DTS ([forums.apple.com/thread/810894](https://developer.apple.com/forums/thread/810894)). Aparece em ~todas as chamadas AVCaptureSession config. **Não tratar como erro.**

### G. Limitações de teste em device físico free tier (sem Apple Developer Program)

- ✅ Debug + Cmd+R: testes G1-G7, G10 funcionam
- ⚠️ Lifecycle G8/G9: testar via Control Center / multitasking parcial (sem fechar app)
- ❌ Release/TestFlight: requer Apple Developer Program ($99/ano) — `Apple Development` certificate sem Dev Program falha code signing

Validação final dos goals em release adiada para quando comprar Dev Program. Em debug, observers de interruption já validam o comportamento esperado.

### H. Logs reais > suposições

Esta validação consumiu ~4-6 horas devido a múltiplos ciclos de "chute → build → testar → não funciona". Quando finalmente capturamos:
- `xclogparser` mostrou builds abortando silenciosamente em Pre-actions
- `os_log` mostrou `minZoom=1.0 clamped=1.0` provando que zoom-ramp não funcionava
- `grep PERMISSION_ ios/Pods/Pods.xcodeproj/project.pbxproj` mostrou macros ausentes

**Cada uma dessas evidências teria sido capturada em <2min** se instrumentação tivesse vindo ANTES dos chutes. Registrado como feedback `feedback_device_debug_use_real_logs_not_assumptions`.

### Memórias adicionais criadas

- `raro-pattern-ios-avcapture-iphone12-dualwide-zoom-mapping` (Apêndice A-F técnico consolidado)
- `raro-pattern-permission-handler-ios-podfile-macros` (Apêndice D)
- `raro-pattern-flutter-debug-vs-release-on-device` (Apêndice G)
- `feedback_device_debug_use_real_logs_not_assumptions` (Apêndice H)
