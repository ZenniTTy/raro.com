# Camera Native Bridge — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar bridge nativa de câmera (iOS AVFoundation + Android CameraX 1.6.1) via Pigeon, com preview ao vivo, alternância de lente 0.5×/1× (virtual camera iOS, swap Android), tap-to-focus, ajuste de resolução/FPS e telemetria — fiel ao P05 do protótipo, sem gravação.

**Architecture:** Pigeon-first contract (Dart ↔ Swift ↔ Kotlin), PlatformView (`UiKitView`/`AndroidView` hybrid composition) renderiza `AVCaptureVideoPreviewLayer` / CameraX `PreviewView`. Feature folder Clean Arch (`application` Riverpod 3 codegen + `data` repo wrapping Pigeon + `domain` value types + `presentation` widgets). Bridge nativa é agnóstica de paywall/replay_buffer/voice/analytics — boundary explícito.

**Tech Stack:** Flutter 3.44, Dart 3.12, Pigeon 26.3.2, Riverpod 3 codegen, iOS 15+ AVFoundation, Android minSdk 24 CameraX 1.6.1, alchemist goldens, mocktail.

**Spec:** `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md`

**ADRs:**
- ADR-0013 (existente) — Pigeon namespace + sub-package Kotlin
- ADR-0014 (existente) — Flutter 3.44 + SPM + iOS 15
- ADR-0015 (criado em Task 2 deste plan) — Camera native bridge strategy

---

## 7 execution rules (sempre aplicar)

1. **Surgical changes** — só toque no que o plan pede.
2. **Sem comentários** em código de produção. Nomes explicam WHAT.
3. **Imports absolutos** via `package:raro_mobile/...` ou `package:raro_shared/...`.
4. **Riverpod 3 codegen** — `@riverpod` annotation + `part '<file>.g.dart'`. Codegen via `bun --filter @raro/mobile run codegen`.
5. **Strict lints** — `flutter analyze` zero issues após cada arquivo modificado.
6. **Strings de UI em `.arb`** — sem inline.
7. **Conventional Commits** — scope do scope-enum. Subject lowercase. Sem `--no-verify`.

## Per-task harness validation (memória persistente, obrigatório)

**Antes de cada commit**, rodar nesta ordem e exigir verde:

```bash
bun --filter @raro/mobile run codegen      # se mudou pigeons/, .arb, ou @riverpod
bun --filter @raro/mobile run analyze      # flutter analyze zero issues
bun --filter @raro/shared run analyze
bun --filter @raro/shared run test
bun --filter @raro/mobile run test         # smoke + contract + novos
```

Se qualquer um falhar: corrigir antes de commit. Nunca `--no-verify`.

## Phase 0 — pre-flight (bloqueante)

- [ ] Spec lida integralmente, status `Draft` → marcar `In implementation` ao iniciar Task 1
- [ ] Q-table preenchida (15 itens, zero `?`)
- [ ] Sizing = Large (confirmado)
- [ ] ADRs identificados: 0013 + 0014 existentes; 0015 será criado em Task 2
- [ ] Branch `feat/camera-native-bridge` (já criada, checkout ok)
- [ ] Harness verde no ponto inicial: `bun --filter @raro/mobile run analyze` + `bun --filter @raro/mobile run test`
- [ ] iPhone físico (12 do usuário) disponível pra device tests no fim
- [ ] Emulador Android Pixel 6 API 34 disponível

---

## File structure (mapa de decomposição)

### packages/shared (Dart puro)

```
packages/shared/lib/src/analytics/analytics_events.dart   # +5 constantes camera
packages/shared/test/analytics_events_test.dart           # asserções de presença
```

### apps/mobile — Pigeon schema

```
apps/mobile/pigeons/camera_api.dart                       # preencher (hoje só ping)
apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart       # regerado
apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift             # regerado
apps/mobile/android/.../generated/camera/CameraApi.g.kt               # regerado
```

### apps/mobile — iOS native

```
apps/mobile/ios/Runner/Native/Camera/
├── CameraManager.swift                  # session lifecycle, capabilities, format, lens
├── CameraPlatformView.swift             # FlutterPlatformView wrapper
├── CameraPlatformViewFactory.swift      # registra com FlutterPluginRegistrar
├── CameraErrorMapper.swift              # Swift Error → CameraErrorCode
└── CameraHostApiImpl.swift              # implementa CameraHostApi (Pigeon gerado)
apps/mobile/ios/Runner/AppDelegate.swift # +registrar factory + HostApi
```

### apps/mobile — Android native

```
apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/
├── CameraManager.kt                     # CameraX lifecycle, capabilities
├── CameraLensDiscovery.kt               # filtra ultra-wide via Camera2 interop
├── CameraPlatformView.kt                # PlatformView (hybrid composition)
├── CameraPlatformViewFactory.kt
├── CameraErrorMapper.kt
└── CameraHostApiImpl.kt                 # implementa CameraHostApi (Pigeon gerado)
apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt  # +registrar
apps/mobile/android/app/build.gradle.kts # +CameraX 1.6.1 deps + camera permission
apps/mobile/android/app/src/main/AndroidManifest.xml  # +CAMERA permission
```

### apps/mobile — Flutter feature

```
apps/mobile/lib/features/camera/
├── application/
│   ├── camera_controller.dart           # @riverpod AsyncNotifier<CameraState>
│   ├── camera_controller.g.dart         # gerado
│   └── camera_analytics_listener.dart   # @riverpod, dispara FirebaseAnalytics
├── data/
│   ├── camera_repository.dart           # abstract
│   ├── camera_repository.g.dart         # @riverpod provider
│   └── pigeon_camera_repository.dart    # impl
├── domain/
│   ├── camera_state.dart                # sealed via freezed
│   ├── camera_state.freezed.dart        # gerado
│   └── camera_settings.dart             # value type
└── presentation/
    ├── camera_preview_widget.dart       # UiKitView / AndroidView
    ├── lens_chip_row.dart               # 0.5×/1× chips
    ├── focus_ring_overlay.dart          # focus ring animado
    ├── rule_of_thirds_painter.dart      # CustomPainter
    └── viewport_grain_painter.dart      # CustomPainter
```

### Tests

```
apps/mobile/test/features/camera/
├── application/camera_controller_test.dart
├── application/camera_analytics_listener_test.dart
├── data/pigeon_camera_repository_test.dart
├── presentation/camera_preview_widget_test.dart
├── presentation/lens_chip_row_test.dart
└── presentation/lens_chip_row_golden_test.dart
apps/mobile/test/contract/
└── camera_bridge_namespace_test.dart    # extensão do bridge_channels_parity_test
```

---

## Atomic tasks

### Task 1 — Pre-flight harness + branch setup

**Files:** none (verification only)

- [ ] **Step 1.1 — Confirm clean state**
```bash
git status
git branch --show-current  # expected: feat/camera-native-bridge
```

- [ ] **Step 1.2 — Baseline harness**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
bun --filter @raro/shared run test
```
Expected: all green. Se vermelho, parar e investigar antes de prosseguir.

- [ ] **Step 1.3 — Marcar spec status**

Edit `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md` linha 5:
```diff
- `Draft`
+ `In implementation`
```

- [ ] **Step 1.4 — Commit**
```bash
git add docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
git commit -m "docs(spec): mark camera-native-bridge in implementation"
```

---

### Task 2 — Criar ADR-0015

**Files:**
- Create: `docs/decisions/0015-camera-native-bridge-strategy.md`

- [ ] **Step 2.1 — Escrever ADR**

Criar `docs/decisions/0015-camera-native-bridge-strategy.md`:

```markdown
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
2. **iOS — VirtualCameraStrategy única.** `builtInTripleCamera` → `builtInDualWideCamera` + `videoZoomFactor` (smooth zoom). YAGNI: iPhones com 0.5× sempre expõem virtual camera. `SwapInputStrategy` documentada como rollback acionável via ADR-update se device test futuro revelar exceção.
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
```

- [ ] **Step 2.2 — Commit**
```bash
git add docs/decisions/0015-camera-native-bridge-strategy.md
git commit -m "docs(docs): adr-0015 camera native bridge strategy"
```

---

### Task 3 — Estender `AnalyticsEvents` em `packages/shared`

**Files:**
- Modify: `packages/shared/lib/src/analytics/analytics_events.dart`
- Modify: `packages/shared/test/analytics_events_test.dart` (ou criar se não existe)

- [ ] **Step 3.1 — Test red: novos eventos ausentes**

Edit `packages/shared/test/analytics_events_test.dart` adicionando:

```dart
import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsEvents — camera extension', () {
    test('cameraStarted is camera_started', () {
      expect(AnalyticsEvents.cameraStarted, 'camera_started');
    });
    test('cameraStopped is camera_stopped', () {
      expect(AnalyticsEvents.cameraStopped, 'camera_stopped');
    });
    test('cameraFocusTapped is camera_focus_tapped', () {
      expect(AnalyticsEvents.cameraFocusTapped, 'camera_focus_tapped');
    });
    test('cameraPermissionDenied is camera_permission_denied', () {
      expect(AnalyticsEvents.cameraPermissionDenied, 'camera_permission_denied');
    });
    test('cameraError is camera_error', () {
      expect(AnalyticsEvents.cameraError, 'camera_error');
    });
  });
}
```

- [ ] **Step 3.2 — Run test, expect FAIL**
```bash
bun --filter @raro/shared run test
```
Expected: FAIL — `cameraStarted` not defined.

- [ ] **Step 3.3 — Implement**

Edit `packages/shared/lib/src/analytics/analytics_events.dart`, adicionar após linha de `xiaomiModalShown`:

```dart
  static const String cameraStarted = 'camera_started';
  static const String cameraStopped = 'camera_stopped';
  static const String cameraFocusTapped = 'camera_focus_tapped';
  static const String cameraPermissionDenied = 'camera_permission_denied';
  static const String cameraError = 'camera_error';
```

- [ ] **Step 3.4 — Run test, expect PASS**
```bash
bun --filter @raro/shared run test
```
Expected: all PASS (5 novos + existentes).

- [ ] **Step 3.5 — Harness validation**
```bash
bun --filter @raro/shared run analyze
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```
Expected: zero issues, zero regressões.

- [ ] **Step 3.6 — Commit**
```bash
git add packages/shared/
git commit -m "feat(analytics): add camera lifecycle events to shared contract"
```

---

### Task 4 — Pigeon schema preenchido (`camera_api.dart`)

**Files:**
- Modify: `apps/mobile/pigeons/camera_api.dart`
- Generated: `apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart`
- Generated: `apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift`
- Generated: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/camera/CameraApi.g.kt`

- [ ] **Step 4.1 — Replace schema**

Substituir todo o conteúdo de `apps/mobile/pigeons/camera_api.dart` por:

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native_bridges/generated/camera_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Native/Generated/CameraApi.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/camera/CameraApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.rarocamera.raro_mobile.generated.camera',
    ),
    dartPackageName: 'raro_mobile',
  ),
)
enum LensType { ultraWide, wide }

enum Resolution { hd720, fhd1080, uhd4k }

enum Fps { fps30, fps60 }

enum CameraErrorCode {
  permissionDenied,
  deviceUnavailable,
  lensUnavailable,
  formatUnsupported,
  sessionFailed,
  alreadyRunning,
  notRunning,
}

class CameraCapabilities {
  CameraCapabilities({
    required this.availableLenses,
    required this.supportedResolutions,
    required this.supportedFps,
  });

  final List<LensType> availableLenses;
  final List<Resolution> supportedResolutions;
  final List<Fps> supportedFps;
}

class CameraConfig {
  CameraConfig({
    required this.lens,
    required this.resolution,
    required this.fps,
  });

  final LensType lens;
  final Resolution resolution;
  final Fps fps;
}

class FocusPoint {
  FocusPoint({required this.x, required this.y});

  final double x;
  final double y;
}

@HostApi()
abstract class CameraHostApi {
  @async
  CameraCapabilities discoverCapabilities();

  @async
  void startSession(int textureId, CameraConfig config);

  @async
  void stopSession();

  @async
  void switchLens(LensType lens);

  @async
  void setFormat(Resolution resolution, Fps fps);

  @async
  void focusAt(FocusPoint point);

  @async
  bool requestPermission();

  @async
  bool hasPermission();
}

@FlutterApi()
abstract class CameraFlutterApi {
  void onSessionStarted(CameraConfig activeConfig);
  void onSessionStopped();
  void onLensSwitched(LensType lens);
  void onFocusChanged(FocusPoint point, bool locked);
  void onError(CameraErrorCode code, String? message);
}
```

- [ ] **Step 4.2 — Run codegen**
```bash
bun --filter @raro/mobile run codegen
```
Expected: gera `camera_api.g.dart` + `CameraApi.g.swift` + `CameraApi.g.kt` sem erro.

- [ ] **Step 4.3 — Verify idempotency**
```bash
bun --filter @raro/mobile run codegen
git status
```
Expected: 2ª rodada não muda nada além de timestamps (Goal G11 da spec).

- [ ] **Step 4.4 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```
Expected: zero issues. Os old `cameraPing`/`cameraReady` foram removidos — qualquer código de produção que os usa quebra agora. Confirmar grep:
```bash
grep -rn "cameraPing\|cameraReady" apps/mobile/lib apps/mobile/ios apps/mobile/android 2>&1 | grep -v ".g."
```
Expected: zero matches (eram só placeholders Pigeon).

- [ ] **Step 4.5 — Commit**
```bash
git add apps/mobile/pigeons/camera_api.dart apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/
git commit -m "feat(bridge): pigeon schema for camera api (lenstype/resolution/fps + hostapi/flutterapi)"
```

---

### Task 5 — Domain types Flutter (`CameraSettings`, `CameraState` freezed)

**Files:**
- Create: `apps/mobile/lib/features/camera/domain/camera_settings.dart`
- Create: `apps/mobile/lib/features/camera/domain/camera_state.dart`
- Generated: `apps/mobile/lib/features/camera/domain/camera_state.freezed.dart`
- Create: `apps/mobile/test/features/camera/domain/camera_state_test.dart`

- [ ] **Step 5.1 — Test red**

Criar `apps/mobile/test/features/camera/domain/camera_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';

void main() {
  group('CameraSettings', () {
    test('toConfig maps to pigeon CameraConfig', () {
      const s = CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps60,
      );
      final c = s.toConfig();
      expect(c.lens, LensType.wide);
      expect(c.resolution, Resolution.fhd1080);
      expect(c.fps, Fps.fps60);
    });
  });

  group('CameraState', () {
    test('idle has capabilities, no error', () {
      final caps = CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      );
      final s = CameraState.idle(capabilities: caps);
      expect(
        s.maybeWhen(idle: (c) => c.availableLenses, orElse: () => null),
        [LensType.wide],
      );
    });

    test('error carries code and message', () {
      final s = CameraState.error(
        code: CameraErrorCode.permissionDenied,
        message: 'denied',
      );
      expect(
        s.maybeWhen(
          error: (c, m) => '$c|$m',
          orElse: () => null,
        ),
        '${CameraErrorCode.permissionDenied}|denied',
      );
    });
  });
}
```

- [ ] **Step 5.2 — Run, expect FAIL**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/domain/camera_state_test.dart
```
Expected: FAIL — types não definidos.

- [ ] **Step 5.3 — Implement `CameraSettings`**

Criar `apps/mobile/lib/features/camera/domain/camera_settings.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

class CameraSettings {
  const CameraSettings({
    required this.lens,
    required this.resolution,
    required this.fps,
  });

  final LensType lens;
  final Resolution resolution;
  final Fps fps;

  CameraConfig toConfig() =>
      CameraConfig(lens: lens, resolution: resolution, fps: fps);

  CameraSettings copyWith({
    LensType? lens,
    Resolution? resolution,
    Fps? fps,
  }) =>
      CameraSettings(
        lens: lens ?? this.lens,
        resolution: resolution ?? this.resolution,
        fps: fps ?? this.fps,
      );
}
```

- [ ] **Step 5.4 — Implement `CameraState`**

Criar `apps/mobile/lib/features/camera/domain/camera_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';

part 'camera_state.freezed.dart';

@freezed
sealed class CameraState with _$CameraState {
  const factory CameraState.idle({required CameraCapabilities capabilities}) =
      CameraStateIdle;
  const factory CameraState.initializing() = CameraStateInitializing;
  const factory CameraState.ready({
    required CameraSettings activeSettings,
    FocusPoint? lastFocusPoint,
  }) = CameraStateReady;
  const factory CameraState.error({
    required CameraErrorCode code,
    String? message,
  }) = CameraStateError;
}
```

- [ ] **Step 5.5 — Codegen freezed**
```bash
bun --filter @raro/mobile run codegen
```
Expected: gera `camera_state.freezed.dart`.

- [ ] **Step 5.6 — Run test, expect PASS**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/domain/camera_state_test.dart
```
Expected: PASS.

- [ ] **Step 5.7 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```
Expected: zero issues, zero regressões.

- [ ] **Step 5.8 — Commit**
```bash
git add apps/mobile/lib/features/camera/domain/ apps/mobile/test/features/camera/domain/
git commit -m "feat(camera): domain types camerasettings + camerastate freezed"
```

---

### Task 6 — `CameraRepository` interface + Pigeon impl + provider

**Files:**
- Create: `apps/mobile/lib/features/camera/data/camera_repository.dart`
- Create: `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart`
- Create: `apps/mobile/lib/features/camera/data/camera_repository_provider.dart`
- Generated: `apps/mobile/lib/features/camera/data/camera_repository_provider.g.dart`
- Create: `apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart`

- [ ] **Step 6.1 — Test red**

Criar `apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/pigeon_camera_repository.dart';

class _MockHostApi extends Mock implements CameraHostApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    registerFallbackValue(FocusPoint(x: 0, y: 0));
  });

  test('discoverCapabilities delegates to host api', () async {
    final api = _MockHostApi();
    when(api.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    final repo = PigeonCameraRepository(api);
    final caps = await repo.discoverCapabilities();
    expect(caps.availableLenses, [LensType.wide]);
  });

  test('startSession forwards textureId + config', () async {
    final api = _MockHostApi();
    when(() => api.startSession(any(), any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.startSession(
      42,
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    verify(() => api.startSession(42, any())).called(1);
  });

  test('focusAt forwards normalized point', () async {
    final api = _MockHostApi();
    when(() => api.focusAt(any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.focusAt(FocusPoint(x: 0.5, y: 0.5));
    verify(() => api.focusAt(any())).called(1);
  });
}
```

- [ ] **Step 6.2 — Run, expect FAIL**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart
```
Expected: FAIL — types ausentes.

- [ ] **Step 6.3 — Implement interface**

Criar `apps/mobile/lib/features/camera/data/camera_repository.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

abstract class CameraRepository {
  Future<CameraCapabilities> discoverCapabilities();
  Future<void> startSession(int textureId, CameraConfig config);
  Future<void> stopSession();
  Future<void> switchLens(LensType lens);
  Future<void> setFormat(Resolution resolution, Fps fps);
  Future<void> focusAt(FocusPoint point);
  Future<bool> requestPermission();
  Future<bool> hasPermission();
}
```

- [ ] **Step 6.4 — Implement Pigeon repo**

Criar `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';

class PigeonCameraRepository implements CameraRepository {
  PigeonCameraRepository(this._api);

  final CameraHostApi _api;

  @override
  Future<CameraCapabilities> discoverCapabilities() =>
      _api.discoverCapabilities();

  @override
  Future<void> startSession(int textureId, CameraConfig config) =>
      _api.startSession(textureId, config);

  @override
  Future<void> stopSession() => _api.stopSession();

  @override
  Future<void> switchLens(LensType lens) => _api.switchLens(lens);

  @override
  Future<void> setFormat(Resolution resolution, Fps fps) =>
      _api.setFormat(resolution, fps);

  @override
  Future<void> focusAt(FocusPoint point) => _api.focusAt(point);

  @override
  Future<bool> requestPermission() => _api.requestPermission();

  @override
  Future<bool> hasPermission() => _api.hasPermission();
}
```

- [ ] **Step 6.5 — Implement Riverpod provider**

Criar `apps/mobile/lib/features/camera/data/camera_repository_provider.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/pigeon_camera_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CameraRepository cameraRepository(Ref ref) =>
    PigeonCameraRepository(CameraHostApi());
```

- [ ] **Step 6.6 — Codegen**
```bash
bun --filter @raro/mobile run codegen
```

- [ ] **Step 6.7 — Run test, expect PASS**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/data/
```
Expected: 3 tests PASS.

- [ ] **Step 6.8 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

- [ ] **Step 6.9 — Commit**
```bash
git add apps/mobile/lib/features/camera/data/ apps/mobile/test/features/camera/data/
git commit -m "feat(camera): repository abstraction wrapping pigeon hostapi"
```

---

### Task 7 — `CameraController` (Riverpod 3 AsyncNotifier)

**Files:**
- Create: `apps/mobile/lib/features/camera/application/camera_controller.dart`
- Generated: `apps/mobile/lib/features/camera/application/camera_controller.g.dart`
- Create: `apps/mobile/test/features/camera/application/camera_controller_test.dart`

- [ ] **Step 7.1 — Test red**

Criar `apps/mobile/test/features/camera/application/camera_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';

class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    registerFallbackValue(FocusPoint(x: 0, y: 0));
  });

  ProviderContainer makeContainer(CameraRepository repo) =>
      ProviderContainer(overrides: [
        cameraRepositoryProvider.overrideWithValue(repo),
      ]);

  test('build returns idle with capabilities', () async {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    final state = await c.read(cameraControllerProvider.future);
    expect(state, isA<CameraStateIdle>());
  });

  test('start transitions idle → initializing → ready', () async {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c.read(cameraControllerProvider.notifier).start(
      textureId: 1,
      settings: const CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateReady>());
  });

  test('start emits error when permission denied', () async {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(() => repo.startSession(any(), any())).thenThrow(
      Exception('CameraErrorCode.permissionDenied'),
    );
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c.read(cameraControllerProvider.notifier).start(
      textureId: 1,
      settings: const CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateError>());
  });
}
```

- [ ] **Step 7.2 — Run, expect FAIL**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/application/camera_controller_test.dart
```

- [ ] **Step 7.3 — Implement controller**

Criar `apps/mobile/lib/features/camera/application/camera_controller.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_controller.g.dart';

@riverpod
class CameraController extends _$CameraController {
  late CameraRepository _repo;

  @override
  Future<CameraState> build() async {
    _repo = ref.watch(cameraRepositoryProvider);
    ref.onDispose(() {
      _repo.stopSession().ignore();
    });
    final caps = await _repo.discoverCapabilities();
    return CameraState.idle(capabilities: caps);
  }

  Future<void> start({
    required int textureId,
    required CameraSettings settings,
  }) async {
    state = const AsyncData(CameraState.initializing());
    try {
      await _repo.startSession(textureId, settings.toConfig());
      state = AsyncData(CameraState.ready(activeSettings: settings));
    } on Object catch (e) {
      state = AsyncData(
        CameraState.error(
          code: CameraErrorCode.sessionFailed,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    await _repo.stopSession();
    final caps = await _repo.discoverCapabilities();
    state = AsyncData(CameraState.idle(capabilities: caps));
  }

  Future<void> switchLens(LensType lens) async {
    await _repo.switchLens(lens);
    final current = state.requireValue;
    if (current is CameraStateReady) {
      state = AsyncData(
        CameraState.ready(
          activeSettings: current.activeSettings.copyWith(lens: lens),
          lastFocusPoint: current.lastFocusPoint,
        ),
      );
    }
  }

  Future<void> setFormat(Resolution resolution, Fps fps) async {
    await _repo.setFormat(resolution, fps);
    final current = state.requireValue;
    if (current is CameraStateReady) {
      state = AsyncData(
        CameraState.ready(
          activeSettings: current.activeSettings
              .copyWith(resolution: resolution, fps: fps),
          lastFocusPoint: current.lastFocusPoint,
        ),
      );
    }
  }

  Future<void> focusAt(double x, double y) async {
    final point = FocusPoint(x: x, y: y);
    await _repo.focusAt(point);
    final current = state.requireValue;
    if (current is CameraStateReady) {
      state = AsyncData(
        CameraState.ready(
          activeSettings: current.activeSettings,
          lastFocusPoint: point,
        ),
      );
    }
  }
}
```

- [ ] **Step 7.4 — Codegen**
```bash
bun --filter @raro/mobile run codegen
```

- [ ] **Step 7.5 — Run test, expect PASS**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/application/camera_controller_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 7.6 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

- [ ] **Step 7.7 — Commit**
```bash
git add apps/mobile/lib/features/camera/application/ apps/mobile/test/features/camera/application/
git commit -m "feat(camera): camera controller riverpod 3 with start/stop/lens/format/focus"
```

---

### Task 8 — Analytics listener (separado do controller)

**Files:**
- Create: `apps/mobile/lib/features/camera/application/camera_analytics_listener.dart`
- Generated: `apps/mobile/lib/features/camera/application/camera_analytics_listener.g.dart`
- Create: `apps/mobile/test/features/camera/application/camera_analytics_listener_test.dart`

- [ ] **Step 8.1 — Test red**

Criar `apps/mobile/test/features/camera/application/camera_analytics_listener_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_analytics_listener.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_shared/raro_shared.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}
class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
  });

  test('emits cameraStarted on ready', () async {
    final analytics = _MockAnalytics();
    when(() => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        )).thenAnswer((_) async {});
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});

    final c = ProviderContainer(overrides: [
      cameraRepositoryProvider.overrideWithValue(repo),
      firebaseAnalyticsProvider.overrideWithValue(analytics),
    ]);
    addTearDown(c.dispose);

    c.listen(cameraAnalyticsListenerProvider, (_, __) {});
    await c.read(cameraControllerProvider.future);
    await c.read(cameraControllerProvider.notifier).start(
      textureId: 1,
      settings: const CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );

    verify(() => analytics.logEvent(
          name: AnalyticsEvents.cameraStarted,
          parameters: any(named: 'parameters'),
        )).called(1);
  });

  test('emits cameraError on error state', () async {
    final analytics = _MockAnalytics();
    when(() => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        )).thenAnswer((_) async {});
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(() => repo.startSession(any(), any())).thenThrow(Exception('fail'));

    final c = ProviderContainer(overrides: [
      cameraRepositoryProvider.overrideWithValue(repo),
      firebaseAnalyticsProvider.overrideWithValue(analytics),
    ]);
    addTearDown(c.dispose);

    c.listen(cameraAnalyticsListenerProvider, (_, __) {});
    await c.read(cameraControllerProvider.future);
    await c.read(cameraControllerProvider.notifier).start(
      textureId: 1,
      settings: const CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );

    verify(() => analytics.logEvent(
          name: AnalyticsEvents.cameraError,
          parameters: any(named: 'parameters'),
        )).called(1);
  });
}
```

- [ ] **Step 8.2 — Run, expect FAIL**

- [ ] **Step 8.3 — Implement provider for FirebaseAnalytics**

Verificar se já existe `firebaseAnalyticsProvider` em `apps/mobile/lib/core/`. Se não, criar minimal em `apps/mobile/lib/core/analytics/firebase_analytics_provider.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_analytics_provider.g.dart';

@Riverpod(keepAlive: true)
FirebaseAnalytics firebaseAnalytics(Ref ref) => FirebaseAnalytics.instance;
```

(Se já existe, reusar e não criar duplicado.)

- [ ] **Step 8.4 — Implement listener**

Criar `apps/mobile/lib/features/camera/application/camera_analytics_listener.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:raro_mobile/core/analytics/firebase_analytics_provider.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_analytics_listener.g.dart';

@Riverpod(keepAlive: true)
CameraAnalyticsListener cameraAnalyticsListener(Ref ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  ref.listen(cameraControllerProvider, (previous, next) {
    next.whenData((state) {
      if (state is CameraStateReady) {
        analytics.logEvent(
          name: AnalyticsEvents.cameraStarted,
          parameters: {
            'lens': state.activeSettings.lens.name,
            'resolution': state.activeSettings.resolution.name,
            'fps': state.activeSettings.fps.name,
          },
        );
      } else if (state is CameraStateError) {
        analytics.logEvent(
          name: AnalyticsEvents.cameraError,
          parameters: {
            'code': state.code.name,
            if (state.message != null) 'message': state.message!,
          },
        );
      }
    });
  });
  return const CameraAnalyticsListener();
}

class CameraAnalyticsListener {
  const CameraAnalyticsListener();
}
```

- [ ] **Step 8.5 — Codegen**
```bash
bun --filter @raro/mobile run codegen
```

- [ ] **Step 8.6 — Run test, expect PASS**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/application/camera_analytics_listener_test.dart
```

- [ ] **Step 8.7 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

- [ ] **Step 8.8 — Commit**
```bash
git add apps/mobile/lib/core/analytics/ apps/mobile/lib/features/camera/application/camera_analytics_listener.dart apps/mobile/lib/features/camera/application/camera_analytics_listener.g.dart apps/mobile/test/features/camera/application/camera_analytics_listener_test.dart
git commit -m "feat(analytics): camera lifecycle events listener via riverpod"
```

---

### Task 9 — iOS native: `CameraManager.swift` + `CameraErrorMapper.swift`

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`
- Create: `apps/mobile/ios/Runner/Native/Camera/CameraErrorMapper.swift`

> Native Swift code has no Dart test harness. Validação iOS é via `flutter build ios --no-codesign --debug` (compila) + integration test em device físico no fim do plan.

- [ ] **Step 9.1 — Implement `CameraErrorMapper`**

Criar `apps/mobile/ios/Runner/Native/Camera/CameraErrorMapper.swift`:

```swift
import AVFoundation
import Foundation

enum CameraNativeError: Error {
  case permissionDenied
  case deviceUnavailable
  case lensUnavailable
  case formatUnsupported
  case sessionFailed(String)
  case alreadyRunning
  case notRunning
}

extension CameraNativeError {
  var code: CameraErrorCode {
    switch self {
    case .permissionDenied: return .permissionDenied
    case .deviceUnavailable: return .deviceUnavailable
    case .lensUnavailable: return .lensUnavailable
    case .formatUnsupported: return .formatUnsupported
    case .sessionFailed: return .sessionFailed
    case .alreadyRunning: return .alreadyRunning
    case .notRunning: return .notRunning
    }
  }

  var message: String? {
    if case let .sessionFailed(msg) = self { return msg }
    return nil
  }
}
```

- [ ] **Step 9.2 — Implement `CameraManager`**

Criar `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`:

```swift
import AVFoundation
import Foundation

final class CameraManager {
  private let sessionQueue = DispatchQueue(label: "com.rarocamera.session")
  private(set) var session: AVCaptureSession?
  private var device: AVCaptureDevice?
  private var input: AVCaptureDeviceInput?

  var onLensSwitched: ((LensType) -> Void)?
  var onError: ((CameraNativeError) -> Void)?

  func hasPermission() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }

  func requestPermission() async -> Bool {
    await AVCaptureDevice.requestAccess(for: .video)
  }

  func discoverCapabilities() throws -> CameraCapabilities {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [
        .builtInTripleCamera,
        .builtInDualWideCamera,
        .builtInUltraWideCamera,
        .builtInWideAngleCamera,
      ],
      mediaType: .video,
      position: .back
    )
    let devices = discovery.devices
    if devices.isEmpty { throw CameraNativeError.deviceUnavailable }

    var lenses: [LensType] = []
    if devices.contains(where: { $0.deviceType == .builtInTripleCamera
        || $0.deviceType == .builtInDualWideCamera
        || $0.deviceType == .builtInUltraWideCamera }) {
      lenses.append(.ultraWide)
    }
    if devices.contains(where: { $0.deviceType == .builtInWideAngleCamera
        || $0.deviceType == .builtInTripleCamera
        || $0.deviceType == .builtInDualWideCamera }) {
      lenses.append(.wide)
    }

    return CameraCapabilities(
      availableLenses: lenses,
      supportedResolutions: [.hd720, .fhd1080, .uhd4k],
      supportedFps: [.fps30, .fps60]
    )
  }

  func startSession(config: CameraConfig) async throws {
    if session != nil { throw CameraNativeError.alreadyRunning }
    guard hasPermission() else { throw CameraNativeError.permissionDenied }

    let device = try selectDevice(for: config.lens)
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: config.resolution, fps: config.fps)
    device.unlockForConfiguration()

    let session = AVCaptureSession()
    session.beginConfiguration()
    let input = try AVCaptureDeviceInput(device: device)
    if session.canAddInput(input) { session.addInput(input) }
    session.commitConfiguration()

    self.session = session
    self.device = device
    self.input = input

    await withCheckedContinuation { cont in
      sessionQueue.async {
        session.startRunning()
        cont.resume()
      }
    }
  }

  func stopSession() {
    sessionQueue.async { [weak self] in
      self?.session?.stopRunning()
      if let inputs = self?.session?.inputs {
        for i in inputs { self?.session?.removeInput(i) }
      }
      self?.session = nil
      self?.device = nil
      self?.input = nil
    }
  }

  func switchLens(_ lens: LensType) throws {
    guard let session = session else { throw CameraNativeError.notRunning }
    let newDevice = try selectDevice(for: lens)
    session.beginConfiguration()
    if let oldInput = self.input { session.removeInput(oldInput) }
    let newInput = try AVCaptureDeviceInput(device: newDevice)
    if session.canAddInput(newInput) { session.addInput(newInput) }
    session.commitConfiguration()
    self.device = newDevice
    self.input = newInput
    onLensSwitched?(lens)
  }

  func setFormat(resolution: Resolution, fps: Fps) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: resolution, fps: fps)
    device.unlockForConfiguration()
  }

  func focusAt(point: FocusPoint) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    guard device.isFocusPointOfInterestSupported else { return }
    try device.lockForConfiguration()
    device.focusPointOfInterest = CGPoint(x: point.x, y: point.y)
    device.focusMode = .autoFocus
    device.unlockForConfiguration()
  }

  private func selectDevice(for lens: LensType) throws -> AVCaptureDevice {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera,
                    .builtInUltraWideCamera, .builtInWideAngleCamera],
      mediaType: .video,
      position: .back
    )

    if lens == .ultraWide {
      if let triple = discovery.devices.first(where: {
        $0.deviceType == .builtInTripleCamera
          || $0.deviceType == .builtInDualWideCamera
      }) {
        triple.videoZoomFactor = max(triple.minAvailableVideoZoomFactor, 0.5)
        return triple
      }
      if let ultra = discovery.devices.first(where: {
        $0.deviceType == .builtInUltraWideCamera
      }) {
        return ultra
      }
      throw CameraNativeError.lensUnavailable
    }

    if let triple = discovery.devices.first(where: {
      $0.deviceType == .builtInTripleCamera
        || $0.deviceType == .builtInDualWideCamera
    }) {
      triple.videoZoomFactor = 1.0
      return triple
    }
    if let wide = discovery.devices.first(where: {
      $0.deviceType == .builtInWideAngleCamera
    }) {
      return wide
    }
    throw CameraNativeError.lensUnavailable
  }

  private func applyFormat(
    device: AVCaptureDevice,
    resolution: Resolution,
    fps: Fps
  ) throws {
    let targetWidth: Int32
    let targetHeight: Int32
    switch resolution {
    case .hd720: targetWidth = 1280; targetHeight = 720
    case .fhd1080: targetWidth = 1920; targetHeight = 1080
    case .uhd4k: targetWidth = 3840; targetHeight = 2160
    }
    let targetFps: Double = fps == .fps60 ? 60 : 30

    let formats = device.formats.filter { format in
      let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      let supportsRes = dims.width == targetWidth && dims.height == targetHeight
      let supportsFps = format.videoSupportedFrameRateRanges.contains {
        $0.minFrameRate <= targetFps && $0.maxFrameRate >= targetFps
      }
      return supportsRes && supportsFps
    }
    guard let chosen = formats.first else { throw CameraNativeError.formatUnsupported }
    device.activeFormat = chosen
    let duration = CMTime(value: 1, timescale: Int32(targetFps))
    device.activeVideoMinFrameDuration = duration
    device.activeVideoMaxFrameDuration = duration
  }
}
```

- [ ] **Step 9.3 — Compile check**
```bash
cd apps/mobile && flutter build ios --no-codesign --debug
```
Expected: build PASS. Se Swift errors aparecerem, ler stderr e corrigir antes de prosseguir.

- [ ] **Step 9.4 — Commit**
```bash
git add apps/mobile/ios/Runner/Native/Camera/CameraManager.swift apps/mobile/ios/Runner/Native/Camera/CameraErrorMapper.swift
git commit -m "feat(bridge): ios camera manager with virtual camera + active format control"
```

---

### Task 10 — iOS native: `CameraHostApiImpl.swift` + `CameraPlatformView.swift` + factory + registration

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift`
- Create: `apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift`
- Create: `apps/mobile/ios/Runner/Native/Camera/CameraPlatformViewFactory.swift`
- Modify: `apps/mobile/ios/Runner/AppDelegate.swift`

- [ ] **Step 10.1 — Implement `CameraHostApiImpl`**

Criar `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift`:

```swift
import Flutter
import Foundation

final class CameraHostApiImpl: NSObject, CameraHostApi {
  private let manager = CameraManager()
  private let flutterApi: CameraFlutterApi

  init(messenger: FlutterBinaryMessenger) {
    self.flutterApi = CameraFlutterApi(binaryMessenger: messenger)
    super.init()
    manager.onLensSwitched = { [weak self] lens in
      DispatchQueue.main.async { self?.flutterApi.onLensSwitched(lens: lens) { _ in } }
    }
    manager.onError = { [weak self] err in
      DispatchQueue.main.async {
        self?.flutterApi.onError(code: err.code, message: err.message) { _ in }
      }
    }
  }

  func discoverCapabilities(
    completion: @escaping (Result<CameraCapabilities, Error>) -> Void
  ) {
    do {
      let caps = try manager.discoverCapabilities()
      completion(.success(caps))
    } catch let err as CameraNativeError {
      completion(.failure(PigeonError(code: "\(err.code.rawValue)", message: err.message, details: nil)))
    } catch {
      completion(.failure(error))
    }
  }

  func startSession(
    textureId: Int64,
    config: CameraConfig,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    Task {
      do {
        try await manager.startSession(config: config)
        DispatchQueue.main.async {
          self.flutterApi.onSessionStarted(activeConfig: config) { _ in }
          completion(.success(()))
        }
      } catch {
        DispatchQueue.main.async { completion(.failure(error)) }
      }
    }
  }

  func stopSession(completion: @escaping (Result<Void, Error>) -> Void) {
    manager.stopSession()
    DispatchQueue.main.async {
      self.flutterApi.onSessionStopped { _ in }
      completion(.success(()))
    }
  }

  func switchLens(
    lens: LensType,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      try manager.switchLens(lens)
      completion(.success(()))
    } catch {
      completion(.failure(error))
    }
  }

  func setFormat(
    resolution: Resolution,
    fps: Fps,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      try manager.setFormat(resolution: resolution, fps: fps)
      completion(.success(()))
    } catch {
      completion(.failure(error))
    }
  }

  func focusAt(
    point: FocusPoint,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      try manager.focusAt(point: point)
      DispatchQueue.main.async {
        self.flutterApi.onFocusChanged(point: point, locked: true) { _ in }
      }
      completion(.success(()))
    } catch {
      completion(.failure(error))
    }
  }

  func requestPermission(completion: @escaping (Result<Bool, Error>) -> Void) {
    Task {
      let granted = await manager.requestPermission()
      DispatchQueue.main.async { completion(.success(granted)) }
    }
  }

  func hasPermission(completion: @escaping (Result<Bool, Error>) -> Void) {
    completion(.success(manager.hasPermission()))
  }

  var cameraManager: CameraManager { manager }
}
```

- [ ] **Step 10.2 — Implement `CameraPlatformView`**

Criar `apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift`:

```swift
import AVFoundation
import Flutter
import UIKit

final class CameraPlatformView: NSObject, FlutterPlatformView {
  private let container = UIView()
  private let previewLayer: AVCaptureVideoPreviewLayer

  init(frame: CGRect, session: AVCaptureSession?) {
    if let session = session {
      previewLayer = AVCaptureVideoPreviewLayer(session: session)
    } else {
      previewLayer = AVCaptureVideoPreviewLayer()
    }
    super.init()
    container.frame = frame
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = container.bounds
    container.layer.addSublayer(previewLayer)
  }

  func view() -> UIView { container }

  func updateSession(_ session: AVCaptureSession) {
    previewLayer.session = session
    previewLayer.frame = container.bounds
  }
}
```

- [ ] **Step 10.3 — Implement factory**

Criar `apps/mobile/ios/Runner/Native/Camera/CameraPlatformViewFactory.swift`:

```swift
import Flutter
import UIKit

final class CameraPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let hostApi: CameraHostApiImpl

  init(hostApi: CameraHostApiImpl) { self.hostApi = hostApi }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let view = CameraPlatformView(frame: frame, session: hostApi.cameraManager.session)
    return view
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}
```

- [ ] **Step 10.4 — Register in `AppDelegate`**

Editar `apps/mobile/ios/Runner/AppDelegate.swift`. Adicionar dentro de `application(_:didFinishLaunchingWithOptions:)`, antes do `return super.application(...)`:

```swift
let controller = window?.rootViewController as! FlutterViewController
let hostApi = CameraHostApiImpl(messenger: controller.binaryMessenger)
CameraHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: hostApi)

let factory = CameraPlatformViewFactory(hostApi: hostApi)
registrar(forPlugin: "com.rarocamera/camera_preview")?.register(
  factory,
  withId: "com.rarocamera/camera_preview"
)
```

- [ ] **Step 10.5 — Compile check**
```bash
cd apps/mobile && flutter build ios --no-codesign --debug
```
Expected: build PASS.

- [ ] **Step 10.6 — Commit**
```bash
git add apps/mobile/ios/Runner/Native/Camera/ apps/mobile/ios/Runner/AppDelegate.swift
git commit -m "feat(bridge): ios camera hostapi impl + platformview + factory registration"
```

---

### Task 11 — Android Gradle deps + manifest permission

**Files:**
- Modify: `apps/mobile/android/app/build.gradle.kts`
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 11.1 — Add CameraX deps**

Editar `apps/mobile/android/app/build.gradle.kts`, na seção `dependencies`:

```kotlin
dependencies {
    implementation("androidx.camera:camera-core:1.6.1")
    implementation("androidx.camera:camera-camera2:1.6.1")
    implementation("androidx.camera:camera-lifecycle:1.6.1")
    implementation("androidx.camera:camera-view:1.6.1")
}
```

(Mantenha demais deps existentes intactas.)

- [ ] **Step 11.2 — Add permission to manifest**

Editar `apps/mobile/android/app/src/main/AndroidManifest.xml`. Adicionar antes do `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

- [ ] **Step 11.3 — Sync gradle**
```bash
cd apps/mobile && flutter build apk --debug
```
Expected: build PASS. Se gradle falhar baixando CameraX, ler stderr.

- [ ] **Step 11.4 — Commit**
```bash
git add apps/mobile/android/app/build.gradle.kts apps/mobile/android/app/src/main/AndroidManifest.xml
git commit -m "build(bridge): add camerax 1.6.1 deps + android camera permission"
```

---

### Task 12 — Android native: `CameraLensDiscovery.kt` + `CameraManager.kt`

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraLensDiscovery.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraErrorMapper.kt`

- [ ] **Step 12.1 — Implement `CameraErrorMapper`**

Criar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraErrorMapper.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode

sealed class CameraNativeException(message: String? = null) : Exception(message) {
  object PermissionDenied : CameraNativeException()
  object DeviceUnavailable : CameraNativeException()
  object LensUnavailable : CameraNativeException()
  object FormatUnsupported : CameraNativeException()
  class SessionFailed(msg: String) : CameraNativeException(msg)
  object AlreadyRunning : CameraNativeException()
  object NotRunning : CameraNativeException()
}

fun CameraNativeException.toCode(): CameraErrorCode = when (this) {
  is CameraNativeException.PermissionDenied -> CameraErrorCode.PERMISSION_DENIED
  is CameraNativeException.DeviceUnavailable -> CameraErrorCode.DEVICE_UNAVAILABLE
  is CameraNativeException.LensUnavailable -> CameraErrorCode.LENS_UNAVAILABLE
  is CameraNativeException.FormatUnsupported -> CameraErrorCode.FORMAT_UNSUPPORTED
  is CameraNativeException.SessionFailed -> CameraErrorCode.SESSION_FAILED
  is CameraNativeException.AlreadyRunning -> CameraErrorCode.ALREADY_RUNNING
  is CameraNativeException.NotRunning -> CameraErrorCode.NOT_RUNNING
}
```

- [ ] **Step 12.2 — Implement `CameraLensDiscovery`**

Criar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraLensDiscovery.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.hardware.camera2.CameraCharacteristics
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.CameraInfo
import androidx.camera.core.CameraSelector
import androidx.camera.lifecycle.ProcessCameraProvider
import com.rarocamera.raro_mobile.generated.camera.LensType

object CameraLensDiscovery {
  @androidx.annotation.OptIn(androidx.camera.camera2.interop.ExperimentalCamera2Interop::class)
  fun availableBackLenses(provider: ProcessCameraProvider): List<LensType> {
    val backInfos = provider.availableCameraInfos.filter {
      it.lensFacing == CameraSelector.LENS_FACING_BACK
    }
    if (backInfos.isEmpty()) return emptyList()

    val focals: List<Pair<CameraInfo, Float>> = backInfos.mapNotNull { info ->
      val ch = Camera2CameraInfo.from(info)
      val f = ch.getCameraCharacteristic(
        CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS
      )?.minOrNull() ?: return@mapNotNull null
      info to f
    }
    if (focals.isEmpty()) return listOf(LensType.WIDE)

    val minFocal = focals.minOf { it.second }
    val hasUltraWide = focals.any { it.second <= minFocal * 1.05f && focals.any { other -> other.second > it.second * 1.3f } }
    return if (hasUltraWide) listOf(LensType.ULTRA_WIDE, LensType.WIDE) else listOf(LensType.WIDE)
  }

  @androidx.annotation.OptIn(androidx.camera.camera2.interop.ExperimentalCamera2Interop::class)
  fun selectorFor(provider: ProcessCameraProvider, lens: LensType): CameraSelector {
    val backInfos = provider.availableCameraInfos.filter {
      it.lensFacing == CameraSelector.LENS_FACING_BACK
    }
    if (lens == LensType.WIDE) return CameraSelector.DEFAULT_BACK_CAMERA

    val ultra = backInfos.minByOrNull { info ->
      Camera2CameraInfo.from(info)
        .getCameraCharacteristic(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        ?.minOrNull() ?: Float.MAX_VALUE
    } ?: throw CameraNativeException.LensUnavailable

    return CameraSelector.Builder()
      .addCameraFilter { infos -> infos.filter { it == ultra } }
      .build()
  }
}
```

- [ ] **Step 12.3 — Implement `CameraManager`**

Criar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.util.Size
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.rarocamera.raro_mobile.generated.camera.CameraCapabilities
import com.rarocamera.raro_mobile.generated.camera.CameraConfig
import com.rarocamera.raro_mobile.generated.camera.FocusPoint
import com.rarocamera.raro_mobile.generated.camera.Fps
import com.rarocamera.raro_mobile.generated.camera.LensType
import com.rarocamera.raro_mobile.generated.camera.Resolution
import java.util.concurrent.TimeUnit

class CameraManager(
  private val context: Context,
  private val lifecycleOwner: LifecycleOwner,
) {
  private var provider: ProcessCameraProvider? = null
  private var preview: Preview? = null
  private var camera: Camera? = null
  private var currentConfig: CameraConfig? = null

  var onLensSwitched: ((LensType) -> Unit)? = null
  var surfaceProvider: Preview.SurfaceProvider? = null

  fun hasPermission(): Boolean =
    ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
      PackageManager.PERMISSION_GRANTED

  suspend fun requestPermission(): Boolean {
    if (hasPermission()) return true
    val activity = context as? Activity ?: return false
    androidx.core.app.ActivityCompat.requestPermissions(
      activity, arrayOf(Manifest.permission.CAMERA), 4242
    )
    return hasPermission()
  }

  fun discoverCapabilities(): CameraCapabilities {
    val p = providerNow()
    val lenses = CameraLensDiscovery.availableBackLenses(p)
    if (lenses.isEmpty()) throw CameraNativeException.DeviceUnavailable
    return CameraCapabilities(
      availableLenses = lenses,
      supportedResolutions = listOf(Resolution.HD720, Resolution.FHD1080, Resolution.UHD4K),
      supportedFps = listOf(Fps.FPS30, Fps.FPS60),
    )
  }

  fun startSession(config: CameraConfig) {
    if (preview != null) throw CameraNativeException.AlreadyRunning
    if (!hasPermission()) throw CameraNativeException.PermissionDenied
    val p = providerNow()
    val selector = CameraLensDiscovery.selectorFor(p, config.lens)
    preview = buildPreview(config.resolution, config.fps).also { pv ->
      surfaceProvider?.let(pv::setSurfaceProvider)
    }
    camera = p.bindToLifecycle(lifecycleOwner, selector, preview)
    currentConfig = config
  }

  fun stopSession() {
    provider?.unbindAll()
    preview = null
    camera = null
    currentConfig = null
  }

  fun switchLens(lens: LensType) {
    val p = providerNow()
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, lens)
    preview = buildPreview(cfg.resolution, cfg.fps).also { pv ->
      surfaceProvider?.let(pv::setSurfaceProvider)
    }
    camera = p.bindToLifecycle(lifecycleOwner, selector, preview)
    currentConfig = cfg.copy(lens = lens)
    onLensSwitched?.invoke(lens)
  }

  fun setFormat(resolution: Resolution, fps: Fps) {
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    val p = providerNow()
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, cfg.lens)
    preview = buildPreview(resolution, fps).also { pv ->
      surfaceProvider?.let(pv::setSurfaceProvider)
    }
    camera = p.bindToLifecycle(lifecycleOwner, selector, preview)
    currentConfig = cfg.copy(resolution = resolution, fps = fps)
  }

  fun focusAt(point: FocusPoint) {
    val cam = camera ?: throw CameraNativeException.NotRunning
    val factory = SurfaceOrientedMeteringPointFactory(1f, 1f)
    val meteringPoint = factory.createPoint(point.x.toFloat(), point.y.toFloat())
    val action = FocusMeteringAction.Builder(meteringPoint)
      .setAutoCancelDuration(5, TimeUnit.SECONDS)
      .build()
    cam.cameraControl.startFocusAndMetering(action)
  }

  private fun providerNow(): ProcessCameraProvider {
    val p = provider ?: ProcessCameraProvider.getInstance(context).get().also {
      provider = it
    }
    return p
  }

  @androidx.annotation.OptIn(androidx.camera.camera2.interop.ExperimentalCamera2Interop::class)
  private fun buildPreview(resolution: Resolution, fps: Fps): Preview {
    val size = when (resolution) {
      Resolution.HD720 -> Size(1280, 720)
      Resolution.FHD1080 -> Size(1920, 1080)
      Resolution.UHD4K -> Size(3840, 2160)
    }
    val targetFps = if (fps == Fps.FPS60) 60 else 30
    val selector = ResolutionSelector.Builder()
      .setResolutionStrategy(
        ResolutionStrategy(size, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER)
      )
      .build()
    val builder = Preview.Builder().setResolutionSelector(selector)
    Camera2Interop.Extender(builder).setCaptureRequestOption(
      android.hardware.camera2.CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
      android.util.Range(targetFps, targetFps)
    )
    return builder.build()
  }
}
```

- [ ] **Step 12.4 — Compile check**
```bash
cd apps/mobile && flutter build apk --debug
```
Expected: build PASS.

- [ ] **Step 12.5 — Commit**
```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/
git commit -m "feat(bridge): android camera manager with camerax 1.6.1 + lens discovery + tap focus"
```

---

### Task 13 — Android native: `CameraHostApiImpl.kt` + `CameraPlatformView.kt` + factory + registration

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformViewFactory.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt`

- [ ] **Step 13.1 — Implement `CameraPlatformView`**

Criar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import io.flutter.plugin.platform.PlatformView

class CameraPlatformView(
  context: Context,
  private val manager: CameraManager,
) : PlatformView {
  private val previewView: PreviewView = PreviewView(context).apply {
    scaleType = PreviewView.ScaleType.FILL_CENTER
  }

  init {
    manager.surfaceProvider = previewView.surfaceProvider
  }

  override fun getView(): View = previewView

  override fun dispose() {
    manager.surfaceProvider = null
  }
}
```

- [ ] **Step 13.2 — Implement factory**

Criar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformViewFactory.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class CameraPlatformViewFactory(
  private val manager: CameraManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
    CameraPlatformView(context, manager)
}
```

- [ ] **Step 13.3 — Implement `CameraHostApiImpl`**

Criar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.os.Handler
import android.os.Looper
import com.rarocamera.raro_mobile.generated.camera.CameraCapabilities
import com.rarocamera.raro_mobile.generated.camera.CameraConfig
import com.rarocamera.raro_mobile.generated.camera.CameraFlutterApi
import com.rarocamera.raro_mobile.generated.camera.CameraHostApi
import com.rarocamera.raro_mobile.generated.camera.FocusPoint
import com.rarocamera.raro_mobile.generated.camera.Fps
import com.rarocamera.raro_mobile.generated.camera.LensType
import com.rarocamera.raro_mobile.generated.camera.Resolution

class CameraHostApiImpl(
  private val manager: CameraManager,
  private val flutterApi: CameraFlutterApi,
) : CameraHostApi {
  private val main = Handler(Looper.getMainLooper())

  init {
    manager.onLensSwitched = { lens ->
      main.post { flutterApi.onLensSwitched(lens) {} }
    }
  }

  override fun discoverCapabilities(callback: (Result<CameraCapabilities>) -> Unit) {
    try { callback(Result.success(manager.discoverCapabilities())) }
    catch (e: Throwable) { callback(Result.failure(e)) }
  }

  override fun startSession(textureId: Long, config: CameraConfig, callback: (Result<Unit>) -> Unit) {
    try {
      manager.startSession(config)
      main.post { flutterApi.onSessionStarted(config) {} }
      callback(Result.success(Unit))
    } catch (e: Throwable) { callback(Result.failure(e)) }
  }

  override fun stopSession(callback: (Result<Unit>) -> Unit) {
    try {
      manager.stopSession()
      main.post { flutterApi.onSessionStopped {} }
      callback(Result.success(Unit))
    } catch (e: Throwable) { callback(Result.failure(e)) }
  }

  override fun switchLens(lens: LensType, callback: (Result<Unit>) -> Unit) {
    try { manager.switchLens(lens); callback(Result.success(Unit)) }
    catch (e: Throwable) { callback(Result.failure(e)) }
  }

  override fun setFormat(resolution: Resolution, fps: Fps, callback: (Result<Unit>) -> Unit) {
    try { manager.setFormat(resolution, fps); callback(Result.success(Unit)) }
    catch (e: Throwable) { callback(Result.failure(e)) }
  }

  override fun focusAt(point: FocusPoint, callback: (Result<Unit>) -> Unit) {
    try {
      manager.focusAt(point)
      main.post { flutterApi.onFocusChanged(point, true) {} }
      callback(Result.success(Unit))
    } catch (e: Throwable) { callback(Result.failure(e)) }
  }

  override fun requestPermission(callback: (Result<Boolean>) -> Unit) {
    kotlinx.coroutines.GlobalScope.launch(kotlinx.coroutines.Dispatchers.Main) {
      callback(Result.success(manager.requestPermission()))
    }
  }

  override fun hasPermission(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(manager.hasPermission()))
  }
}
```

- [ ] **Step 13.4 — Register in `MainActivity`**

Editar `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt`. Adicionar `configureFlutterEngine`:

```kotlin
package com.rarocamera.raro_mobile

import com.rarocamera.raro_mobile.camera.CameraHostApiImpl
import com.rarocamera.raro_mobile.camera.CameraManager
import com.rarocamera.raro_mobile.camera.CameraPlatformViewFactory
import com.rarocamera.raro_mobile.generated.camera.CameraFlutterApi
import com.rarocamera.raro_mobile.generated.camera.CameraHostApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    val manager = CameraManager(applicationContext, this)
    val flutterApi = CameraFlutterApi(messenger)
    val hostApi = CameraHostApiImpl(manager, flutterApi)
    CameraHostApi.setUp(messenger, hostApi)
    flutterEngine
      .platformViewsController
      .registry
      .registerViewFactory(
        "com.rarocamera/camera_preview",
        CameraPlatformViewFactory(manager)
      )
  }
}
```

- [ ] **Step 13.5 — Compile check**
```bash
cd apps/mobile && flutter build apk --debug
```
Expected: PASS.

- [ ] **Step 13.6 — Commit**
```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/
git commit -m "feat(bridge): android camera hostapi impl + platformview + factory registration"
```

---

### Task 14 — Flutter UI: `CameraPreviewWidget` + painters

**Files:**
- Create: `apps/mobile/lib/features/camera/presentation/camera_preview_widget.dart`
- Create: `apps/mobile/lib/features/camera/presentation/rule_of_thirds_painter.dart`
- Create: `apps/mobile/lib/features/camera/presentation/viewport_grain_painter.dart`
- Create: `apps/mobile/lib/features/camera/presentation/focus_ring_overlay.dart`
- Create: `apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart`

- [ ] **Step 14.1 — Test red**

Criar `apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';

void main() {
  testWidgets('renders rule-of-thirds and grain overlays', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CameraPreviewWidget()),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
  });
}
```

- [ ] **Step 14.2 — Run, expect FAIL**

- [ ] **Step 14.3 — Implement painters**

Criar `apps/mobile/lib/features/camera/presentation/rule_of_thirds_painter.dart`:

```dart
import 'package:flutter/material.dart';

class RuleOfThirdsPainter extends CustomPainter {
  const RuleOfThirdsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    final w3 = size.width / 3;
    final h3 = size.height / 3;
    canvas.drawLine(Offset(w3, 0), Offset(w3, size.height), paint);
    canvas.drawLine(Offset(w3 * 2, 0), Offset(w3 * 2, size.height), paint);
    canvas.drawLine(Offset(0, h3), Offset(size.width, h3), paint);
    canvas.drawLine(Offset(0, h3 * 2), Offset(size.width, h3 * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

Criar `apps/mobile/lib/features/camera/presentation/viewport_grain_painter.dart`:

```dart
import 'dart:math';
import 'package:flutter/material.dart';

class ViewportGrainPainter extends CustomPainter {
  const ViewportGrainPainter({this.seed = 42});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    final dotCount = (size.width * size.height / 600).round();
    for (var i = 0; i < dotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ViewportGrainPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
```

- [ ] **Step 14.4 — Implement focus ring overlay**

Criar `apps/mobile/lib/features/camera/presentation/focus_ring_overlay.dart`:

```dart
import 'package:flutter/material.dart';

class FocusRingOverlay extends StatefulWidget {
  const FocusRingOverlay({super.key, required this.position});

  final Offset position;

  @override
  State<FocusRingOverlay> createState() => _FocusRingOverlayState();
}

class _FocusRingOverlayState extends State<FocusRingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 1.4, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 32,
      top: widget.position.dy - 32,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 14.5 — Implement preview widget**

Criar `apps/mobile/lib/features/camera/presentation/camera_preview_widget.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/presentation/focus_ring_overlay.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';

const String _viewType = 'com.rarocamera/camera_preview';

class CameraPreviewWidget extends ConsumerStatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  ConsumerState<CameraPreviewWidget> createState() => _State();
}

class _State extends ConsumerState<CameraPreviewWidget> {
  Offset? _focus;

  @override
  Widget build(BuildContext context) {
    final platformView = Platform.isIOS
        ? const UiKitView(viewType: _viewType, creationParams: <String, Object?>{},
            creationParamsCodec: StandardMessageCodec())
        : const AndroidView(
            viewType: _viewType,
            creationParams: <String, Object?>{},
            creationParamsCodec: StandardMessageCodec(),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) async {
            final pos = details.localPosition;
            setState(() => _focus = pos);
            final nx = (pos.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final ny = (pos.dy / constraints.maxHeight).clamp(0.0, 1.0);
            await ref.read(cameraControllerProvider.notifier).focusAt(nx, ny);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              platformView,
              const IgnorePointer(
                child: CustomPaint(painter: RuleOfThirdsPainter()),
              ),
              const IgnorePointer(
                child: CustomPaint(painter: ViewportGrainPainter()),
              ),
              if (_focus != null)
                FocusRingOverlay(
                  key: ValueKey(_focus),
                  position: _focus!,
                ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 14.6 — Run test, expect PASS**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart
```

- [ ] **Step 14.7 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

- [ ] **Step 14.8 — Commit**
```bash
git add apps/mobile/lib/features/camera/presentation/ apps/mobile/test/features/camera/presentation/
git commit -m "feat(camera): preview widget with rule-of-thirds + grain + focus ring overlays"
```

---

### Task 15 — Flutter UI: `LensChipRow` + golden

**Files:**
- Create: `apps/mobile/lib/features/camera/presentation/lens_chip_row.dart`
- Create: `apps/mobile/test/features/camera/presentation/lens_chip_row_test.dart`
- Create: `apps/mobile/test/features/camera/presentation/lens_chip_row_golden_test.dart`

- [ ] **Step 15.1 — Test red (behavior)**

Criar `apps/mobile/test/features/camera/presentation/lens_chip_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/presentation/lens_chip_row.dart';

void main() {
  testWidgets('hides ultraWide chip when unavailable', (tester) async {
    LensType? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LensChipRow(
            availableLenses: const [LensType.wide],
            selected: LensType.wide,
            onSelected: (l) => tapped = l,
          ),
        ),
      ),
    );
    expect(find.text('0.5×'), findsNothing);
    expect(find.text('1×'), findsOneWidget);
  });

  testWidgets('emits onSelected when tapping a chip', (tester) async {
    LensType? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LensChipRow(
            availableLenses: const [LensType.ultraWide, LensType.wide],
            selected: LensType.wide,
            onSelected: (l) => tapped = l,
          ),
        ),
      ),
    );
    await tester.tap(find.text('0.5×'));
    expect(tapped, LensType.ultraWide);
  });
}
```

- [ ] **Step 15.2 — Run, expect FAIL**

- [ ] **Step 15.3 — Implement**

Criar `apps/mobile/lib/features/camera/presentation/lens_chip_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

class LensChipRow extends StatelessWidget {
  const LensChipRow({
    super.key,
    required this.availableLenses,
    required this.selected,
    required this.onSelected,
  });

  final List<LensType> availableLenses;
  final LensType selected;
  final ValueChanged<LensType> onSelected;

  String _labelFor(LensType l) => l == LensType.ultraWide ? '0.5×' : '1×';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final lens in availableLenses) ...[
          _Chip(
            label: _labelFor(lens),
            selected: lens == selected,
            onTap: () => onSelected(lens),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 15.4 — Run test, expect PASS**

- [ ] **Step 15.5 — Golden test**

Criar `apps/mobile/test/features/camera/presentation/lens_chip_row_golden_test.dart`:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/presentation/lens_chip_row.dart';

void main() {
  goldenTest(
    'lens_chip_row',
    fileName: 'lens_chip_row',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'both available, wide selected',
          child: LensChipRow(
            availableLenses: const [LensType.ultraWide, LensType.wide],
            selected: LensType.wide,
            onSelected: (_) {},
          ),
        ),
        GoldenTestScenario(
          name: 'only wide available',
          child: LensChipRow(
            availableLenses: const [LensType.wide],
            selected: LensType.wide,
            onSelected: (_) {},
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 15.6 — Generate goldens**
```bash
cd apps/mobile && flutter test --update-goldens test/features/camera/presentation/lens_chip_row_golden_test.dart
```
Expected: gera arquivos `.png` em `test/features/camera/presentation/goldens/`.

- [ ] **Step 15.7 — Run goldens, expect PASS**
```bash
bun --filter @raro/mobile run test apps/mobile/test/features/camera/presentation/lens_chip_row_golden_test.dart
```

- [ ] **Step 15.8 — Harness validation**
```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

- [ ] **Step 15.9 — Commit**
```bash
git add apps/mobile/lib/features/camera/presentation/lens_chip_row.dart apps/mobile/test/features/camera/presentation/lens_chip_row_test.dart apps/mobile/test/features/camera/presentation/lens_chip_row_golden_test.dart apps/mobile/test/features/camera/presentation/goldens/
git commit -m "feat(camera): lens chip row 0.5x/1x with goldens"
```

---

### Task 16 — Contract test extension: namespace `com.rarocamera/camera_preview`

**Files:**
- Modify: `apps/mobile/test/contract/bridge_channels_parity_test.dart` (ou criar `camera_bridge_namespace_test.dart`)

- [ ] **Step 16.1 — Inspect existing test**
```bash
cat apps/mobile/test/contract/bridge_channels_parity_test.dart | head -40
```

- [ ] **Step 16.2 — Add test case**

Editar `apps/mobile/test/contract/bridge_channels_parity_test.dart` adicionando:

```dart
test('camera_preview platform view registered in iOS and Android', () {
  final iosFile = File('ios/Runner/AppDelegate.swift').readAsStringSync();
  expect(iosFile, contains('com.rarocamera/camera_preview'));

  final androidFile = File(
    'android/app/src/main/kotlin/com/rarocamera/raro_mobile/MainActivity.kt',
  ).readAsStringSync();
  expect(androidFile, contains('com.rarocamera/camera_preview'));
});
```

- [ ] **Step 16.3 — Run, expect PASS** (já que Tasks 10 e 13 registraram a viewType)
```bash
bun --filter @raro/mobile run test apps/mobile/test/contract/bridge_channels_parity_test.dart
```

- [ ] **Step 16.4 — Commit**
```bash
git add apps/mobile/test/contract/bridge_channels_parity_test.dart
git commit -m "test(contract): assert camera_preview platformview registered ios + android"
```

---

### Task 17 — Validador + design-fidelity

- [ ] **Step 17.1 — Run validator subagent**

Dispatch:
```
Subagent: validator
Prompt: Audite a implementação de feat/camera-native-bridge contra a spec docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md. Verifique:
- Pigeon schema cobre todas as ops/enums/data classes declarados na Seção 2 da spec
- iOS CameraManager usa VirtualCameraStrategy (não Swap) conforme Q2/ADR-0015
- CameraX 1.6.1 pinado em build.gradle.kts
- AnalyticsEvents tem 5 novas constantes (Task 3)
- bridge_channels_parity_test cobre 'com.rarocamera/camera_preview'
- Boundary preservado: bridge nativa não chama Firebase direto
- Imports absolutos (sem ../../../)
- Zero literais de UI inline
- Zero ocorrências de OkCamera

Reporte: SPEC_COMPLIANT | ISSUES (lista) | NOTES (não-bloqueantes).
```

- [ ] **Step 17.2 — Run design-fidelity-checker**

Dispatch:
```
Subagent: design-fidelity-checker
Prompt: Compare apps/mobile/lib/features/camera/presentation/ contra docs/briefing/prototype/Prototipo-RARO.html função screenCamera() (linhas 825+). Foque em:
- Viewport com grain overlay (.viewport-grain)
- Rule-of-thirds linhas guides
- Focus ring (.focus-ring): scale-in + fade 1.2s
- Lens chips 0.5×/1× — estilo, padding, border, opacity

Reporte: FIDELITY_OK | DEVIATIONS (lista).
```

- [ ] **Step 17.3 — Corrigir issues reportados**

Se validator ou design-fidelity reportarem issues, criar commit `fix(camera): post-audit corrections — <descrição>` corrigindo cada um. Re-rodar até verde.

- [ ] **Step 17.4 — Cross-doc consistency audit (memória persistente)**

Antes de declarar Done, manual:
```bash
grep -rn "TBD\|gerado por\|commits a inserir\|preencher" docs/sessions/ docs/decisions/ docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md docs/10-CHANGELOG.md
```
Expected: zero matches.

---

### Task 18 — CHANGELOG + Session log + marcar spec Done

**Files:**
- Modify: `docs/10-CHANGELOG.md`
- Create: `docs/sessions/0004-camera-native-bridge.md`
- Modify: `docs/sessions/0001-INDEX.md`
- Modify: `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md` (status Done)

- [ ] **Step 18.1 — CHANGELOG entry**

Adicionar topo de `docs/10-CHANGELOG.md`:

```markdown
## [0.4.0] — 2026-05-26

### Added
- Camera native bridge (iOS AVFoundation + Android CameraX 1.6.1) com preview ao vivo, lens switch 0.5×/1×, tap-to-focus, format control (720p/1080p/4K @ 30/60fps)
- ADR-0015 (Camera native bridge strategy)
- AnalyticsEvents: cameraStarted, cameraStopped, cameraFocusTapped, cameraPermissionDenied, cameraError
- Contract test bridge_channels_parity_test cobre com.rarocamera/camera_preview

### Notes
- Sem gravação ainda (depende de feat/replay-buffer-native-bridge)
- iPad rejeitado via deviceUnavailable error
```

- [ ] **Step 18.2 — Session log**

Criar `docs/sessions/0004-camera-native-bridge.md` documentando: data, branch, commits SHAs range, decisões durante implementação, desvios do plan, gates verdes, próxima sessão sugerida.

- [ ] **Step 18.3 — Update INDEX**

Adicionar linha 7 de `docs/sessions/0001-INDEX.md` (após a linha 0003):

```markdown
| [0004](0004-camera-native-bridge.md) | 2026-05-26 | camera-native-bridge (preview + lens + focus + format, ADR-0015) | `feat/camera-native-bridge` | <SHA start> … <SHA end> (N commits) |
```

- [ ] **Step 18.4 — Marcar spec Done**

Editar `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md` linha 5:
```diff
- `In implementation`
+ `Done`
```

E marcar todas observable goals checked `[x]` que de fato passaram em device test.

- [ ] **Step 18.5 — Commit**
```bash
git add docs/10-CHANGELOG.md docs/sessions/0004-camera-native-bridge.md docs/sessions/0001-INDEX.md docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
git commit -m "docs(docs): close camera-native-bridge session 0004 + changelog 0.4.0"
```

---

### Task 19 — Device tests (iPhone físico + Android emulador) + memory profiling

> **Esta task exige o usuário** — pause aqui e peça aprovação para conectar iPhone 12.

- [ ] **Step 19.1 — iPhone 12 device test**

Pedir ao usuário pra conectar iPhone 12 via USB. Confirmar via:
```bash
flutter devices
```
Esperar device listado.

```bash
cd apps/mobile && flutter run -d <iphone-12-id>
```

Validar observable goals via app temporário (tela mínima com `CameraPreviewWidget` + chips + start/stop buttons):
- G1 (start ≤500ms) — cronometrar manualmente
- G2 (capabilities = [ultraWide, wide])
- G3 (lens switch <100ms perceptível)
- G4 (focus ring ≤200ms + fade 1.2s)
- G5 (resolução muda runtime)
- G6 (4K@60 ativo — verificar Settings nativo)
- G7 (memória ±5MB pós-stop via Xcode Instruments)
- G8 (permission denied → fallback UI)
- G9 (background→foreground retoma)

- [ ] **Step 19.2 — Android emulador test**

```bash
flutter emulators --launch Pixel_6_API_34
cd apps/mobile && flutter run -d emulator-5554
```

Validar mesmas goals (memória via Memory Profiler do Android Studio).

- [ ] **Step 19.3 — Documentar resultados**

Atualizar session log com matriz device × goal × pass/fail.

- [ ] **Step 19.4 — Commit (se necessário)**

Se ajustes finos forem encontrados em device test, fix commits + atualizar goldens conforme necessário. Re-rodar harness validation.

- [ ] **Step 19.5 — Marcar Done definitivo**

Confirmar todos `[x]` em observable goals da spec. Se algum falhar irrecuperável em device, documentar como tech-debt no session log e marcar goal como `[~]` com nota.

---

## Done when (definition of done)

- [ ] Todas atomic tasks 1–19 ✅
- [ ] `bun --filter @raro/mobile run analyze` zero issues
- [ ] `bun --filter @raro/mobile run test` zero regressões (smoke + contract + 14 novos)
- [ ] `bun --filter @raro/shared run test` zero regressões (5 novos AnalyticsEvents)
- [ ] `flutter build ios --no-codesign --debug` PASS
- [ ] `flutter build apk --debug` PASS
- [ ] `validator` subagent confirma SPEC_COMPLIANT
- [ ] `design-fidelity-checker` confirma FIDELITY_OK contra P05
- [ ] Goldens regerados e visualmente aprovados
- [ ] Native bridge contract test verde (camera_preview namespace)
- [ ] Device tests em iPhone 12 verde (Goals G1–G10)
- [ ] Device tests em emulador Android verde
- [ ] ADR-0015 mergeado
- [ ] CHANGELOG 0.4.0 entry
- [ ] Session log 0004 + INDEX atualizado
- [ ] Spec marcada `Done`
- [ ] Cross-doc audit: zero placeholders em sessions/decisions/specs/changelog
- [ ] Branch pode ser merged em `develop` via `--no-ff`

## Rollback plan

Se a feature precisar ser revertida:

1. `git revert <range>` desde `Task 4` (Pigeon schema) — não usar `reset --hard` em commits pushados
2. Restaurar `apps/mobile/pigeons/camera_api.dart` ao estado ping-only (Task 4 reversal)
3. Re-rodar `bun --filter @raro/mobile run codegen` para limpar generated
4. Marcar ADR-0015 como `Reverted` com nota apontando para commit de revert
5. Spec marcada `Superseded by ...` ou `Reverted`
6. CHANGELOG entry de revert
7. Session log explicando motivo (regression em produção, decisão de produto, etc.)

## Tech debt registrado (não bloqueante)

- Pigeon ^26.3.4 (aguarda theme_tailor + riverpod_lint analyzer ^10.0.0). Atualmente em ^26.3.2 (Caso B do ADR-0014).
- Feature flag `cameraUseVirtualStrategy` via Firebase Remote Config — não aplicado nesta spec (YAGNI strategy única). Adicionar via ADR-update se device test futuro revelar exceção.
- TextureId lifecycle — atualmente passa `0` placeholder (PlatformView gerencia surface direto). Refinar se replay_buffer exigir Texture Registry separado.
- Background queue iOS (`makeBackgroundTaskQueue()`) — não implementado nesta spec (discovery rápido o suficiente em iPhone moderno). Adicionar se profiling mostrar bloqueio.
- HUD completo P05 (top bar, REC, timer, buffer bar, hint, record button, gallery/settings icons, grad-line) — spec `feat/camera-hud`.
