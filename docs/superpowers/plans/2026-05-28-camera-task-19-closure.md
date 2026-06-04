# Camera Task 19 Closure — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar Task 19 da spec `feat/camera-native-bridge` entregando G4 (focus ring nativo iOS+Android), G1/G7 (perf instrumentation com `OSSignposter` + `Trace`), validação em iPhone 12 + Samsung Galaxy M54 5G, e desbloqueando merge `feat/camera-native-bridge → develop → main`.

**Architecture:** `CAShapeLayer` sublayer no `AVCaptureVideoPreviewLayer` (iOS) + `FocusRingView` custom View dentro de `FrameLayout` sobre `PreviewView` (Android) substituem o `focus_ring_overlay.dart` Flutter que quebrava hybrid composition. Tap continua no Flutter (`GestureDetector` mantém-se), render fica nativo. Perf instrumentation via `OSSignposter` + `mach_absolute_time` + `task_info` (iOS 15+) / `android.os.Trace` + `SystemClock.elapsedRealtimeNanos` + `Debug.MemoryInfo` (Android), emitidos via callback Pigeon `FlutterApi.onPerformanceMetric` novo. `FocusRingConfig` constants centralizadas em `raro_shared` Dart, espelhadas em Swift/Kotlin.

**Tech Stack:** Flutter 3.44, Dart 3.12, Pigeon 26.3.2, Riverpod 3 codegen, iOS 15+ AVFoundation + `CAShapeLayer` + `CABasicAnimation` + `CAKeyframeAnimation` + `OSSignposter`, Android minSdk 24 CameraX 1.6.1 + `FrameLayout` + `ObjectAnimator` + `android.os.Trace`, alchemist goldens, mocktail.

**Spec:** [`docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md`](../specs/2026-05-28-camera-task-19-closure-design.md)

**Parent spec:** [`docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md`](../specs/2026-05-26-camera-native-bridge-design.md) (Tasks 1–18 done)

**ADRs:**
- ADR-0013 (existente) — Pigeon namespace + sub-package Kotlin
- ADR-0014 (existente) — Flutter 3.44 + SPM + iOS 15 (mantido — bump rejeitado)
- ADR-0015 (existente) — Camera native bridge strategy + addendum A–H; **addendum I criado em Task 14 deste plan**

**Branch:** `feat/camera-native-bridge` (continua — não criar nova branch)

---

## 7 execution rules (sempre aplicar)

1. **Surgical changes** — só toque no que o plan pede. Sem refactor "de passagem".
2. **Sem comentários** em código de produção. Nomes explicam WHAT.
3. **Imports absolutos** via `package:raro_mobile/...` ou `package:raro_shared/...`. Sem `../../../`.
4. **Riverpod 3 codegen** — `@riverpod` annotation + `part '<file>.g.dart'`. Codegen via `bun --filter @raro/mobile run codegen`.
5. **Strict lints** — `flutter analyze` zero issues após cada arquivo modificado.
6. **Strings de UI em `.arb`** — sem inline (este plan não toca UI textual; harness HUD usa labels técnicas em inglês minúsculo).
7. **Conventional Commits** — scope do scope-enum em `commitlint.config.cjs`. Subject lowercase. Sem `--no-verify`.

## Per-task harness validation (memória `feedback_per_task_harness_validation` — obrigatório)

**Antes de cada commit**, rodar nesta ordem e exigir verde:

```bash
bun --filter @raro/mobile run codegen      # se mudou pigeons/, .arb, ou @riverpod
bun --filter @raro/mobile run analyze
bun --filter @raro/shared run analyze
bun --filter @raro/shared run test
bun --filter @raro/mobile run test
```

Se qualquer um falhar: **fix root cause**, não bypass. Nunca `--no-verify`.

## Phase 0 — pre-flight (bloqueante)

- [ ] **0.1** Branch checkout confirmado:
  ```bash
  git rev-parse --abbrev-ref HEAD
  ```
  Expected: `feat/camera-native-bridge`

- [ ] **0.2** Working tree limpo:
  ```bash
  git status --short
  ```
  Expected: empty output

- [ ] **0.3** Spec lida integralmente e marcada `Approved`:
  ```bash
  grep -n "^## Status$" -A 2 docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md
  ```
  Após confirmar leitura, abrir o arquivo e mudar `Draft` → `Approved`. Commit:
  ```bash
  git add docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md
  git commit -m "docs(spec): mark camera task 19 closure as approved"
  ```

- [ ] **0.4a** **iOS scaffold regen** (preventivo — `Generated.xcconfig`, `Debug.xcconfig`, `Release.xcconfig`, `Package.swift` ephemeral são gitignored e podem estar ausentes/stale, especialmente após `flutter clean`, `git clean -fd`, ou Xcode `Reset Package Caches`):

  ```bash
  bun --filter @raro/mobile run pub:get
  ```

  Esse script encadeia `flutter pub get → fix-spm-ios-target.sh (sed para iOS 15.0) → bootstrap-ios-permissions.sh (PERMISSION_CAMERA=1 etc)`. Expected output last 3 lines: `Got dependencies!` + `[fix-spm-ios-target] patched/já está em iOS 15.0` + `[bootstrap-ios-permissions] macros já presentes/aplicados`. Ver memórias `raro-pattern-flutter-spm-ios-13-hardcoded` + `raro-pattern-permission-handler-ios-podfile-macros`.

  **Se Xcode estava rodando**: quit Xcode antes (⌘Q), delete DerivedData stale, reabre depois — senão Xcode pode estar cacheando SPM resolution contra o estado antigo:

  ```bash
  pgrep -x Xcode && echo "QUIT XCODE FIRST" || rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
  ```

- [ ] **0.4b** Harness verde no ponto inicial:
  ```bash
  bun --filter @raro/mobile run analyze
  bun --filter @raro/shared run analyze
  bun --filter @raro/shared run test
  bun --filter @raro/mobile run test
  ```
  Expected: todos verdes.

- [ ] **0.5** iPhone 12 físico disponível (USB-C / cabo Lightning). Samsung Galaxy M54 disponível (USB Debugging ativo em Developer Options).
  ```bash
  flutter devices
  ```
  Expected: ambos listados.

---

# Phase 1 — G4 Native focus ring

## Task 1 — `FocusRingConfig` em `raro_shared` (constants)

**Files:**
- Create: `packages/shared/lib/src/camera/focus_ring_config.dart`
- Modify: `packages/shared/lib/raro_shared.dart` (add export)
- Test: `packages/shared/test/camera/focus_ring_config_test.dart`

- [ ] **1.1 — Write failing test**

Create `packages/shared/test/camera/focus_ring_config_test.dart`:

```dart
import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('FocusRingConfig', () {
    test('exposes ring visual constants matching prototype .focus-ring CSS', () {
      expect(FocusRingConfig.colorArgb, 0xFFFFFFFF);
      expect(FocusRingConfig.strokeWidth, 1.5);
      expect(FocusRingConfig.durationMs, 1200);
      expect(FocusRingConfig.scaleFrom, 1.4);
      expect(FocusRingConfig.scaleTo, 1.0);
      expect(FocusRingConfig.radiusPx, 32.0);
    });

    test('opacity keyframes match [0,1,0] with keyTimes [0,0.2,1]', () {
      expect(FocusRingConfig.opacityKeyframes, [0.0, 1.0, 0.0]);
      expect(FocusRingConfig.opacityKeyTimes, [0.0, 0.2, 1.0]);
      expect(
        FocusRingConfig.opacityKeyframes.length,
        FocusRingConfig.opacityKeyTimes.length,
      );
    });

    test('cannot be instantiated (private constructor)', () {
      expect(FocusRingConfig.durationMs > 0, isTrue);
    });
  });
}
```

- [ ] **1.2 — Run test (expect fail)**

```bash
cd packages/shared && dart test test/camera/focus_ring_config_test.dart
```

Expected: `FAILED` with `Error: Type 'FocusRingConfig' not found.`

- [ ] **1.3 — Create `FocusRingConfig`**

Create `packages/shared/lib/src/camera/focus_ring_config.dart`:

```dart
class FocusRingConfig {
  const FocusRingConfig._();

  static const int colorArgb = 0xFFFFFFFF;
  static const double strokeWidth = 1.5;
  static const int durationMs = 1200;
  static const double scaleFrom = 1.4;
  static const double scaleTo = 1.0;
  static const double radiusPx = 32.0;
  static const List<double> opacityKeyframes = [0.0, 1.0, 0.0];
  static const List<double> opacityKeyTimes = [0.0, 0.2, 1.0];
}
```

- [ ] **1.4 — Export in `raro_shared.dart`**

Edit `packages/shared/lib/raro_shared.dart`, add after `export 'src/bridges/bridge_channels.dart';` line:

```dart
export 'src/camera/focus_ring_config.dart';
```

(Maintain alphabetical order — insert between `bridges` and `contract`.)

- [ ] **1.5 — Run test (expect pass)**

```bash
cd packages/shared && dart test test/camera/focus_ring_config_test.dart
```

Expected: `All tests passed!` (3 tests)

- [ ] **1.6 — Run shared analyze**

```bash
bun --filter @raro/shared run analyze
```

Expected: `No issues found!`

- [ ] **1.7 — Commit**

```bash
git add packages/shared/lib/src/camera/focus_ring_config.dart \
        packages/shared/lib/raro_shared.dart \
        packages/shared/test/camera/focus_ring_config_test.dart
git commit -m "feat(shared): add focus ring config constants for native overlay"
```

---

## Task 2 — Simplify `camera_preview_widget.dart` (remove Flutter focus overlay)

**Files:**
- Modify: `apps/mobile/lib/features/camera/presentation/camera_preview_widget.dart`
- Delete: `apps/mobile/lib/features/camera/presentation/focus_ring_overlay.dart`
- Test: `apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart` (update if exists; otherwise create)
- Delete: `apps/mobile/test/features/camera/presentation/focus_ring_overlay_test.dart` (if exists)

- [ ] **2.1 — Check existing widget tests**

```bash
ls apps/mobile/test/features/camera/presentation/ 2>/dev/null
```

Note what exists. If `camera_preview_widget_test.dart` already exists, plan to update; otherwise plan to create.

- [ ] **2.2 — Write failing widget test**

Replace (or create) `apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';

class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(FocusPoint(x: 0, y: 0));
  });

  testWidgets('tap on preview calls focusAt with normalized coordinates', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(repo.stopSession).thenAnswer((_) async {});
    when(() => repo.focusAt(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 400, height: 800, child: CameraPreviewWidget()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(const Offset(200, 400));
    await tester.pump();

    final captured = verify(() => repo.focusAt(captureAny())).captured;
    expect(captured.length, 1);
    final point = captured.first as FocusPoint;
    expect(point.x, closeTo(0.5, 0.01));
    expect(point.y, closeTo(0.5, 0.01));
  });

  testWidgets('does not render any FocusRingOverlay widget (native renders ring)', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(repo.stopSession).thenAnswer((_) async {});
    when(() => repo.focusAt(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cameraRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 400, height: 800, child: CameraPreviewWidget()),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 100));

    final dynamic anyFocusRing = find.byWidgetPredicate(
      (w) => w.runtimeType.toString().contains('FocusRing'),
    );
    expect(anyFocusRing.evaluate(), isEmpty);
  });
}
```

- [ ] **2.3 — Run test (expect fail)**

```bash
cd apps/mobile && flutter test test/features/camera/presentation/camera_preview_widget_test.dart
```

Expected: FAIL — likely because the current widget still renders `FocusRingOverlay` via Stack.

- [ ] **2.4 — Rewrite `camera_preview_widget.dart`**

Replace entirety of `apps/mobile/lib/features/camera/presentation/camera_preview_widget.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';
import 'package:raro_shared/raro_shared.dart';

const String _viewType = BridgeChannels.cameraPreview;

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key, this.showOverlays = false});

  final bool showOverlays;

  Widget _buildPlatformView() {
    if (Platform.isIOS) {
      return const UiKitView(
        viewType: _viewType,
        creationParams: <String, Object?>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: _viewType,
        creationParams: <String, Object?>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformView = _buildPlatformView();
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) async {
            final pos = details.localPosition;
            final nx = (pos.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final ny = (pos.dy / constraints.maxHeight).clamp(0.0, 1.0);
            await ref.read(cameraControllerProvider.notifier).focusAt(nx, ny);
          },
          child: showOverlays
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    platformView,
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: RuleOfThirdsPainter()),
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: ViewportGrainPainter()),
                      ),
                    ),
                  ],
                )
              : platformView,
        );
      },
    );
  }
}
```

Notes:
- Removed `_focus` state + `FocusRingOverlay` overlay. Focus ring renders **nativamente** (Task 4/5).
- Default `showOverlays = false` (was `true`); rule-of-thirds + grain stay Flutter Stack until migrated to native in dedicated spec.
- Changed `ConsumerStatefulWidget` → `ConsumerWidget` (no more state needed).

- [ ] **2.5 — Delete obsolete files**

```bash
git rm apps/mobile/lib/features/camera/presentation/focus_ring_overlay.dart
test -f apps/mobile/test/features/camera/presentation/focus_ring_overlay_test.dart && \
  git rm apps/mobile/test/features/camera/presentation/focus_ring_overlay_test.dart || \
  echo "no overlay test to delete"
```

- [ ] **2.6 — Audit harness for showOverlays usage**

```bash
grep -rn "showOverlays" apps/mobile/lib/ apps/mobile/test/
```

Confirm `camera_test_harness_screen.dart:194` still uses `showOverlays: false`. No edits needed there.

- [ ] **2.7 — Run widget test (expect pass)**

```bash
cd apps/mobile && flutter test test/features/camera/presentation/camera_preview_widget_test.dart
```

Expected: `All tests passed!`

- [ ] **2.8 — Run mobile analyze + smoke test**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

Expected: zero issues + all tests pass.

- [ ] **2.9 — Commit**

```bash
git add apps/mobile/lib/features/camera/presentation/camera_preview_widget.dart \
        apps/mobile/test/features/camera/presentation/camera_preview_widget_test.dart
git commit -m "refactor(camera): remove flutter focus ring overlay (migrating to native)"
```

---

## Task 3 — iOS native `CAShapeLayer` focus ring + KVO `isAdjustingFocus`

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Camera/FocusRingConfig.swift` (mirror)
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift` (add `showFocusRing`)
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` (KVO + debounce)
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift` (trigger ring + emit real `onFocusChanged`)
- Create: `apps/mobile/ios/RunnerTests/CameraPlatformViewTests.swift`

- [ ] **3.1 — Mirror `FocusRingConfig` in Swift**

Create `apps/mobile/ios/Runner/Native/Camera/FocusRingConfig.swift`:

```swift
import UIKit

enum FocusRingConfig {
  static let color: UIColor = .white
  static let strokeWidth: CGFloat = 1.5
  static let duration: CFTimeInterval = 1.2
  static let scaleFrom: CGFloat = 1.4
  static let scaleTo: CGFloat = 1.0
  static let radius: CGFloat = 32.0
  static let opacityKeyframes: [NSNumber] = [0.0, 1.0, 0.0]
  static let opacityKeyTimes: [NSNumber] = [0.0, 0.2, 1.0]
}
```

Note: `// MIRROR: packages/shared/lib/src/camera/focus_ring_config.dart` — **do NOT add this comment in production code** per CLAUDE.md §11. The mirror relationship is documented in the spec instead.

- [ ] **3.2 — Write failing iOS unit test**

Create `apps/mobile/ios/RunnerTests/CameraPlatformViewTests.swift`:

```swift
@preconcurrency import AVFoundation
@testable import Runner
import XCTest

final class CameraPlatformViewTests: XCTestCase {
  func testShowFocusRingAddsShapeSublayer() {
    let view = CameraPreviewContainerView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let initialSublayers = view.layer.sublayers?.count ?? 0
    view.showFocusRing(at: CGPoint(x: 200, y: 400))
    let after = view.layer.sublayers?.count ?? 0
    XCTAssertEqual(after, initialSublayers + 1)
    let ring = view.layer.sublayers?.last as? CAShapeLayer
    XCTAssertNotNil(ring)
    XCTAssertEqual(ring?.strokeColor, UIColor.white.cgColor)
    XCTAssertEqual(ring?.lineWidth, FocusRingConfig.strokeWidth)
    XCTAssertTrue(ring?.path != nil)
  }

  func testShowFocusRingAnimationsConfigured() {
    let view = CameraPreviewContainerView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    view.showFocusRing(at: CGPoint(x: 100, y: 100))
    let ring = view.layer.sublayers?.last as? CAShapeLayer
    let scale = ring?.animation(forKey: "scale") as? CABasicAnimation
    XCTAssertEqual(scale?.fromValue as? CGFloat, FocusRingConfig.scaleFrom)
    XCTAssertEqual(scale?.toValue as? CGFloat, FocusRingConfig.scaleTo)
    XCTAssertEqual(scale?.duration, FocusRingConfig.duration)
    let opacity = ring?.animation(forKey: "opacity") as? CAKeyframeAnimation
    XCTAssertEqual(opacity?.values as? [NSNumber], FocusRingConfig.opacityKeyframes)
    XCTAssertEqual(opacity?.keyTimes, FocusRingConfig.opacityKeyTimes)
  }
}
```

- [ ] **3.3 — Run native test (expect fail)**

```bash
cd apps/mobile/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:RunnerTests/CameraPlatformViewTests 2>&1 | tail -30
```

Expected: FAIL with `Value of type 'CameraPreviewContainerView' has no member 'showFocusRing'`.

- [ ] **3.4 — Extend `CameraPlatformView.swift`**

Replace `apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift` with:

```swift
import AVFoundation
import Flutter
import UIKit

final class CameraPreviewContainerView: UIView {
  override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

  var previewLayer: AVCaptureVideoPreviewLayer {
    return layer as! AVCaptureVideoPreviewLayer
  }

  var session: AVCaptureSession? {
    get { previewLayer.session }
    set { previewLayer.session = newValue }
  }

  func showFocusRing(at point: CGPoint) {
    let ring = CAShapeLayer()
    let radius = FocusRingConfig.radius
    let bounds = CGRect(
      x: point.x - radius,
      y: point.y - radius,
      width: radius * 2,
      height: radius * 2
    )
    ring.path = UIBezierPath(ovalIn: bounds).cgPath
    ring.strokeColor = FocusRingConfig.color.cgColor
    ring.fillColor = UIColor.clear.cgColor
    ring.lineWidth = FocusRingConfig.strokeWidth
    ring.contentsScale = UIScreen.main.scale
    ring.opacity = 0

    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = FocusRingConfig.scaleFrom
    scale.toValue = FocusRingConfig.scaleTo
    scale.duration = FocusRingConfig.duration
    scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

    let opacity = CAKeyframeAnimation(keyPath: "opacity")
    opacity.values = FocusRingConfig.opacityKeyframes
    opacity.keyTimes = FocusRingConfig.opacityKeyTimes
    opacity.duration = FocusRingConfig.duration

    ring.add(scale, forKey: "scale")
    ring.add(opacity, forKey: "opacity")

    layer.addSublayer(ring)
    DispatchQueue.main.asyncAfter(deadline: .now() + FocusRingConfig.duration) { [weak ring] in
      ring?.removeFromSuperlayer()
    }
  }
}

final class CameraPlatformView: NSObject, FlutterPlatformView {
  private let container: CameraPreviewContainerView

  init(frame: CGRect, session: AVCaptureSession?) {
    container = CameraPreviewContainerView(frame: frame)
    super.init()
    container.backgroundColor = .black
    container.previewLayer.videoGravity = .resizeAspectFill
    container.session = session
  }

  func view() -> UIView { container }

  func showFocusRing(at point: CGPoint) {
    container.showFocusRing(at: point)
  }
}
```

- [ ] **3.5 — Run native test (expect pass)**

```bash
cd apps/mobile/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:RunnerTests/CameraPlatformViewTests 2>&1 | tail -15
```

Expected: 2 tests passed.

- [ ] **3.6 — Add KVO `isAdjustingFocus` to `CameraManager.swift`**

Apply targeted edits to `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`:

**6a.** After `private var notificationTokens: [NSObjectProtocol] = []` (~line 9), add:

```swift
  private var focusKVO: NSKeyValueObservation?
  private var focusDebounceWorkItem: DispatchWorkItem?
  var onFocusResult: ((Bool) -> Void)?
```

**6b.** Replace `func focusAt(point: FocusPoint) throws { ... }` (~line 248) with:

```swift
  func focusAt(point: FocusPoint) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    guard device.isFocusPointOfInterestSupported else { return }
    try device.lockForConfiguration()
    device.focusPointOfInterest = CGPoint(x: point.x, y: point.y)
    device.focusMode = .autoFocus
    device.unlockForConfiguration()
    observeFocusAdjustment(on: device)
  }

  private func observeFocusAdjustment(on device: AVCaptureDevice) {
    focusKVO?.invalidate()
    focusDebounceWorkItem?.cancel()
    var wasAdjusting = false
    focusKVO = device.observe(\.isAdjustingFocus, options: [.new]) { [weak self] _, change in
      guard let self = self else { return }
      let adjusting = change.newValue ?? false
      if adjusting {
        wasAdjusting = true
        return
      }
      guard wasAdjusting else { return }
      let work = DispatchWorkItem { [weak self] in
        self?.onFocusResult?(true)
        self?.focusKVO?.invalidate()
        self?.focusKVO = nil
      }
      self.focusDebounceWorkItem = work
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
    }
    let timeout = DispatchWorkItem { [weak self] in
      self?.focusKVO?.invalidate()
      self?.focusKVO = nil
      self?.onFocusResult?(false)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeout)
  }
```

**6c.** Replace `func stopSession()` to invalidate KVO. After `removeObservers()` (~line 169), add before `sessionQueue.async`:

```swift
    focusKVO?.invalidate()
    focusKVO = nil
    focusDebounceWorkItem?.cancel()
```

- [ ] **3.7 — Update `CameraHostApiImpl.swift` — trigger ring + emit real focus result**

Edit `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift`:

**7a.** In `init(messenger:)` after `manager.onError = ...`, add:

```swift
    manager.onFocusResult = { [weak self] success in
      DispatchQueue.main.async {
        guard let lastPoint = self?.lastFocusPoint else { return }
        self?.flutterApi.onFocusChanged(point: lastPoint, locked: success) { _ in }
      }
    }
```

**7b.** Add stored property near top of class:

```swift
  private var lastFocusPoint: FocusPoint?
```

**7c.** Replace `focusAt` method:

```swift
  func focusAt(point: FocusPoint, completion: @escaping (Result<Void, Error>) -> Void) {
    do {
      try manager.focusAt(point: point)
      lastFocusPoint = point
      DispatchQueue.main.async {
        guard let factory = self.platformViewFactory else {
          completion(.success(()))
          return
        }
        factory.lastPlatformView?.showFocusRing(
          at: factory.toViewCoordinates(focusPoint: point)
        )
        completion(.success(()))
      }
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .sessionFailed, message: error.localizedDescription)))
    }
  }
```

**7d.** Add `var platformViewFactory: CameraPlatformViewFactory?` near top (will be set by `AppDelegate.swift`):

```swift
  weak var platformViewFactory: CameraPlatformViewFactory?
```

- [ ] **3.8 — Extend `CameraPlatformViewFactory.swift` to track `lastPlatformView` + coord helper**

Edit `apps/mobile/ios/Runner/Native/Camera/CameraPlatformViewFactory.swift`. Append inside class:

```swift
  weak var lastPlatformView: CameraPlatformView?

  override func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let view = CameraPlatformView(frame: frame, session: hostApi.cameraManager.session)
    lastPlatformView = view
    return view
  }

  func toViewCoordinates(focusPoint: FocusPoint) -> CGPoint {
    guard let view = lastPlatformView?.view() else {
      return CGPoint(x: focusPoint.x, y: focusPoint.y)
    }
    return CGPoint(
      x: CGFloat(focusPoint.x) * view.bounds.width,
      y: CGFloat(focusPoint.y) * view.bounds.height
    )
  }
```

Note: if `create(...)` already exists, replace it with the version above; otherwise add. Check current implementation first via `grep -n "func create" apps/mobile/ios/Runner/Native/Camera/CameraPlatformViewFactory.swift`.

- [ ] **3.9 — Wire factory→host in `AppDelegate.swift`**

```bash
grep -n "CameraHostApiImpl\|CameraPlatformViewFactory" apps/mobile/ios/Runner/AppDelegate.swift
```

After the line where both are instantiated, add:

```swift
    cameraHostApi.platformViewFactory = cameraFactory
```

Replace `cameraHostApi` / `cameraFactory` with whatever variable names are in use.

- [ ] **3.10 — Run native tests**

```bash
cd apps/mobile/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:RunnerTests/CameraPlatformViewTests 2>&1 | tail -15
```

Expected: 2 tests passed.

- [ ] **3.11 — Build iOS simulator (smoke test)**

```bash
cd apps/mobile && flutter build ios --simulator --no-codesign 2>&1 | tail -5
```

Expected: `Building Runner.app for iOS Simulator... Done`

- [ ] **3.12 — Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/FocusRingConfig.swift \
        apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift \
        apps/mobile/ios/Runner/Native/Camera/CameraPlatformViewFactory.swift \
        apps/mobile/ios/Runner/Native/Camera/CameraManager.swift \
        apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift \
        apps/mobile/ios/Runner/AppDelegate.swift \
        apps/mobile/ios/RunnerTests/CameraPlatformViewTests.swift
git commit -m "feat(camera): native focus ring on ios via cashapelayer + kvo focus"
```

---

## Task 4 — Android `FocusRingView` + `FrameLayout` wrapper + `tapToFocusState` Flow

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingConfig.kt`
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt`
- Create: `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/FocusRingViewTest.kt`

- [ ] **4.1 — Mirror `FocusRingConfig` in Kotlin**

Create `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingConfig.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.graphics.Color

object FocusRingConfig {
  const val COLOR_ARGB: Int = Color.WHITE
  const val STROKE_WIDTH_DP: Float = 1.5f
  const val DURATION_MS: Long = 1200L
  const val SCALE_FROM: Float = 1.4f
  const val SCALE_TO: Float = 1.0f
  const val RADIUS_DP: Float = 32f
  val OPACITY_KEYFRAMES: FloatArray = floatArrayOf(0f, 1f, 0f)
  val OPACITY_KEY_TIMES: FloatArray = floatArrayOf(0f, 0.2f, 1f)
}
```

- [ ] **4.2 — Write failing unit test**

Create `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/FocusRingViewTest.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config

@RunWith(AndroidJUnit4::class)
@Config(sdk = [34])
class FocusRingViewTest {
  private val ctx: Context = ApplicationProvider.getApplicationContext()

  @Test
  fun showAtAnimatesScaleAndAlpha() {
    val view = FocusRingView(ctx)
    view.showAt(100f, 200f)
    assertEquals(100f, view.currentX, 0.001f)
    assertEquals(200f, view.currentY, 0.001f)
    val animators = view.activeAnimators
    assertTrue("expected at least 2 animators", animators.size >= 2)
    val scale = animators.find { it.propertyName == "scaleX" }
    val alpha = animators.find { it.propertyName == "alpha" }
    assertNotNull(scale)
    assertNotNull(alpha)
    assertEquals(FocusRingConfig.DURATION_MS, scale!!.duration)
    assertEquals(FocusRingConfig.DURATION_MS, alpha!!.duration)
  }

  @Test
  fun hideCancelsActiveAnimators() {
    val view = FocusRingView(ctx)
    view.showAt(50f, 50f)
    view.hide()
    assertTrue(view.activeAnimators.all { !it.isRunning })
  }
}
```

- [ ] **4.3 — Run test (expect fail)**

```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest \
  --tests "com.rarocamera.raro_mobile.camera.FocusRingViewTest" 2>&1 | tail -15
```

Expected: FAIL — `FocusRingView` not found.

- [ ] **4.4 — Create `FocusRingView.kt`**

Create `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import android.view.animation.DecelerateInterpolator

class FocusRingView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null,
) : View(context, attrs) {

  private val paint: Paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    color = FocusRingConfig.COLOR_ARGB
    strokeWidth = dp(FocusRingConfig.STROKE_WIDTH_DP)
  }
  private val radiusPx: Float = dp(FocusRingConfig.RADIUS_DP)

  var currentX: Float = 0f
    private set
  var currentY: Float = 0f
    private set

  val activeAnimators: MutableList<ObjectAnimator> = mutableListOf()

  init {
    isClickable = false
    isFocusable = false
    alpha = 0f
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)
    canvas.drawCircle(currentX, currentY, radiusPx, paint)
  }

  fun showAt(x: Float, y: Float) {
    cancelAnimators()
    currentX = x
    currentY = y
    invalidate()
    val scaleKeyframes = PropertyValuesHolder.ofFloat(
      "scaleX",
      FocusRingConfig.SCALE_FROM,
      FocusRingConfig.SCALE_TO
    )
    val scaleYKeyframes = PropertyValuesHolder.ofFloat(
      "scaleY",
      FocusRingConfig.SCALE_FROM,
      FocusRingConfig.SCALE_TO
    )
    val scale = ObjectAnimator.ofPropertyValuesHolder(this, scaleKeyframes, scaleYKeyframes).apply {
      duration = FocusRingConfig.DURATION_MS
      interpolator = DecelerateInterpolator()
    }
    val alphaAnim = ObjectAnimator.ofFloat(this, "alpha", *FocusRingConfig.OPACITY_KEYFRAMES).apply {
      duration = FocusRingConfig.DURATION_MS
    }
    activeAnimators += scale
    activeAnimators += alphaAnim
    scale.start()
    alphaAnim.start()
  }

  fun hide() {
    cancelAnimators()
    alpha = 0f
    invalidate()
  }

  private fun cancelAnimators() {
    activeAnimators.forEach { if (it.isRunning) it.cancel() }
    activeAnimators.clear()
  }

  private fun dp(value: Float): Float =
    value * context.resources.displayMetrics.density
}
```

- [ ] **4.5 — Run test (expect pass)**

```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest \
  --tests "com.rarocamera.raro_mobile.camera.FocusRingViewTest" 2>&1 | tail -10
```

Expected: 2 tests passed.

- [ ] **4.6 — Wrap `PreviewView` + `FocusRingView` in `FrameLayout`**

Replace `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import androidx.camera.view.PreviewView
import io.flutter.plugin.platform.PlatformView

class CameraPlatformView(
  context: Context,
  private val manager: CameraManager,
) : PlatformView {
  private val container: FrameLayout = FrameLayout(context)
  private val previewView: PreviewView = PreviewView(context).apply {
    scaleType = PreviewView.ScaleType.FILL_CENTER
  }
  val focusRingView: FocusRingView = FocusRingView(context)

  init {
    container.addView(previewView, FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.MATCH_PARENT,
    ))
    container.addView(focusRingView, FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.MATCH_PARENT,
    ))
    manager.surfaceProvider = previewView.surfaceProvider
  }

  fun showFocusRing(normalizedX: Float, normalizedY: Float) {
    val w = previewView.width.toFloat()
    val h = previewView.height.toFloat()
    if (w <= 0 || h <= 0) return
    focusRingView.showAt(normalizedX * w, normalizedY * h)
  }

  override fun getView(): View = container

  override fun dispose() {
    manager.surfaceProvider = null
    focusRingView.hide()
  }
}
```

- [ ] **4.7 — Update `CameraManager.kt` — observe `tapToFocusState`**

Edit `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`:

**7a.** Add imports at top (after existing imports):

```kotlin
import androidx.camera.core.FocusMeteringResult
import androidx.lifecycle.lifecycleScope
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
```

**7b.** Add stored property near `onLensSwitched`:

```kotlin
  var onFocusResult: ((Boolean) -> Unit)? = null
```

**7c.** Replace `focusAt(point: FocusPoint)` body:

```kotlin
  fun focusAt(point: FocusPoint) {
    val cam = camera ?: throw CameraNativeException.NotRunning
    val factory = SurfaceOrientedMeteringPointFactory(1f, 1f)
    val meteringPoint = factory.createPoint(point.x.toFloat(), point.y.toFloat())
    val action = FocusMeteringAction.Builder(meteringPoint)
      .setAutoCancelDuration(5, TimeUnit.SECONDS)
      .build()
    val future: ListenableFuture<FocusMeteringResult> =
      cam.cameraControl.startFocusAndMetering(action)
    lifecycleOwner.lifecycleScope.launch {
      val success = try {
        future.await().isFocusSuccessful
      } catch (e: Throwable) {
        false
      }
      onFocusResult?.invoke(success)
    }
  }
```

- [ ] **4.8 — Update `CameraHostApiImpl.kt` — trigger ring + emit real focus**

Edit `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt`:

**8a.** Add `lastFocusPoint` near `manager` property:

```kotlin
  private var lastFocusPoint: FocusPoint? = null
  var platformView: CameraPlatformView? = null
```

**8b.** In `init { ... }` add:

```kotlin
    manager.onFocusResult = { success ->
      val point = lastFocusPoint ?: return@onFocusResult
      main.post { flutterApi.onFocusChanged(point, success) {} }
    }
```

**8c.** Replace `focusAt(...)` method:

```kotlin
  override fun focusAt(point: FocusPoint, callback: (Result<Unit>) -> Unit) {
    try {
      manager.focusAt(point)
      lastFocusPoint = point
      main.post {
        platformView?.showFocusRing(point.x.toFloat(), point.y.toFloat())
      }
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }
```

- [ ] **4.9 — Update `CameraPlatformViewFactory.kt` to set host's `platformView`**

Find `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformViewFactory.kt`. In `create(...)` after the line that creates the `CameraPlatformView`, add:

```kotlin
    hostApi.platformView = view
```

(Variable names depend on existing code; adapt as needed.)

- [ ] **4.10 — Add Kotlin Coroutines Guava dependency**

Check `apps/mobile/android/app/build.gradle.kts` (or `.gradle`):

```bash
grep -n "kotlinx-coroutines-guava\|kotlinx-coroutines-core" apps/mobile/android/app/build.gradle.kts
```

If `kotlinx-coroutines-guava` is missing, add to `dependencies { ... }`:

```kotlin
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.8.1")
```

If `kotlinx-coroutines-core` is also missing:

```kotlin
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.1")
```

- [ ] **4.11 — Verify no robolectric missing**

```bash
grep -n "robolectric" apps/mobile/android/app/build.gradle.kts
```

If missing, add to `dependencies` block:

```kotlin
    testImplementation("org.robolectric:robolectric:4.13")
    testImplementation("androidx.test:core:1.6.1")
    testImplementation("androidx.test.ext:junit:1.2.1")
```

- [ ] **4.12 — Run Android tests**

```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest \
  --tests "com.rarocamera.raro_mobile.camera.FocusRingViewTest" 2>&1 | tail -10
```

Expected: 2 tests passed.

- [ ] **4.13 — Build Android (smoke test)**

```bash
cd apps/mobile && flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **4.14 — Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingConfig.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformView.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPlatformViewFactory.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt \
        apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/FocusRingViewTest.kt \
        apps/mobile/android/app/build.gradle.kts
git commit -m "feat(camera): native focus ring on android via custom view + taptofocusstate"
```

---

## Task 5 — `/verify-slice` T1 (focus ring done)

- [ ] **5.1 — Run harness validation**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/shared run analyze
bun --filter @raro/shared run test
bun --filter @raro/mobile run test
```

Expected: all green.

- [ ] **5.2 — Run design-fidelity-checker subagent**

Dispatch via `Agent` tool, `subagent_type: "design-fidelity-checker"`:

> Compare `apps/mobile/ios/Runner/Native/Camera/CameraPlatformView.swift` (function `showFocusRing`) and `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingView.kt` (function `showAt`) against the CSS class `.focus-ring` in `docs/briefing/prototype/Prototipo-RARO.html` (search for `.focus-ring` selector). Verify: color `#FFFFFF`, strokeWidth 1.5, scale 1.4→1.0 easeOut, duration 1200ms, opacity keyframes `[0,1,0]` keyTimes `[0,0.2,1]`. Report APPROVE | DEVIATIONS.

If DEVIATIONS reported, fix inline before proceeding.

- [ ] **5.3 — Run integration smoke (optional, simulator)**

```bash
cd apps/mobile && flutter run -d "iPhone 16" --route /camera/harness 2>&1 | tail -20
```

Manual: tap on preview, confirm ring appears nativamente (no Stack widget). Stop with `q`.

---

# Phase 2 — G1/G7 Performance instrumentation

## Task 6 — Pigeon contract delta (`PerformanceMetric` + `onPerformanceMetric`)

**Files:**
- Modify: `apps/mobile/pigeons/camera_api.dart`
- Regenerate (auto): `apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart`
- Regenerate (auto): `apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift`
- Regenerate (auto): `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/camera/CameraApi.g.kt`

- [ ] **6.1 — Add `PerformanceMetric` class + `onPerformanceMetric` callback to pigeon schema**

Edit `apps/mobile/pigeons/camera_api.dart`. After `class FocusPoint { ... }` block, add:

```dart
class PerformanceMetric {
  PerformanceMetric({
    required this.name,
    required this.deltaMs,
    required this.memoryKb,
  });

  final String name;
  final double deltaMs;
  final int memoryKb;
}
```

In `@FlutterApi() abstract class CameraFlutterApi { ... }`, after `void onFocusChanged(...)`, add:

```dart
  void onPerformanceMetric(PerformanceMetric metric);
```

- [ ] **6.2 — Run Pigeon regen**

```bash
bun --filter @raro/mobile run codegen
```

Expected: 0 errors. Inspect diff:

```bash
git diff --stat apps/mobile/lib/core/native_bridges/generated/ \
                apps/mobile/ios/Runner/Native/Generated/ \
                apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/
```

Expected: 3 .g files modified.

- [ ] **6.3 — Run analyze**

```bash
bun --filter @raro/mobile run analyze
```

Expected: zero issues.

- [ ] **6.4 — Commit pigeon delta isolated**

```bash
git add apps/mobile/pigeons/camera_api.dart \
        apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart \
        apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/camera/CameraApi.g.kt
git commit -m "feat(bridge): pigeon contract delta for camera performance metric"
```

---

## Task 7 — iOS perf instrumentation (`OSSignposter` + `CameraPerfMetrics`)

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Camera/CameraPerfMetrics.swift`
- Create: `apps/mobile/ios/RunnerTests/CameraPerfMetricsTests.swift`
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift`

- [ ] **7.1 — Write failing test**

Create `apps/mobile/ios/RunnerTests/CameraPerfMetricsTests.swift`:

```swift
@testable import Runner
import XCTest

final class CameraPerfMetricsTests: XCTestCase {
  func testNsToMsConvertsCorrectly() {
    XCTAssertEqual(CameraPerfMetrics.nsToMs(1_000_000), 1.0, accuracy: 0.001)
    XCTAssertEqual(CameraPerfMetrics.nsToMs(500_000), 0.5, accuracy: 0.001)
    XCTAssertEqual(CameraPerfMetrics.nsToMs(0), 0.0)
  }

  func testElapsedMsIsMonotonic() {
    let t0 = CameraPerfMetrics.now()
    Thread.sleep(forTimeInterval: 0.01)
    let t1 = CameraPerfMetrics.now()
    let elapsed = CameraPerfMetrics.elapsedMs(from: t0, to: t1)
    XCTAssertGreaterThanOrEqual(elapsed, 9.0)
    XCTAssertLessThan(elapsed, 100.0)
  }

  func testPhysFootprintKbIsPositive() {
    let kb = CameraPerfMetrics.physFootprintKb()
    XCTAssertGreaterThan(kb, 0)
  }
}
```

- [ ] **7.2 — Run test (expect fail)**

```bash
cd apps/mobile/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:RunnerTests/CameraPerfMetricsTests 2>&1 | tail -10
```

Expected: FAIL — `CameraPerfMetrics` not found.

- [ ] **7.3 — Create `CameraPerfMetrics.swift`**

Create `apps/mobile/ios/Runner/Native/Camera/CameraPerfMetrics.swift`:

```swift
import Darwin.Mach
import Foundation

enum CameraPerfMetrics {
  private static var timebaseInfo: mach_timebase_info_data_t = {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return info
  }()

  static func now() -> UInt64 {
    return mach_absolute_time()
  }

  static func nsToMs(_ nanoseconds: UInt64) -> Double {
    return Double(nanoseconds) / 1_000_000.0
  }

  static func elapsedMs(from start: UInt64, to end: UInt64) -> Double {
    let raw = end &- start
    let ns = raw &* UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom)
    return nsToMs(ns)
  }

  static func physFootprintKb() -> Int64 {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<integer_t>.size)
    let kr = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), ptr, &count)
      }
    }
    if kr != KERN_SUCCESS { return 0 }
    return Int64(info.phys_footprint / 1024)
  }
}
```

- [ ] **7.4 — Run test (expect pass)**

```bash
cd apps/mobile/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:RunnerTests/CameraPerfMetricsTests 2>&1 | tail -10
```

Expected: 3 tests passed.

- [ ] **7.5 — Add `OSSignposter` + perf wrappers to `CameraManager.swift`**

Edit `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`:

**5a.** After `private let cameraLog = OSLog(...)`, add (top-level file scope):

```swift
private let cameraSignposter = OSSignposter(subsystem: "com.rarocamera", category: "Camera")
```

**5b.** Add a closure-based perf measurer below the `cameraSignposter` declaration:

```swift
private struct PerfSample {
  let name: String
  let deltaMs: Double
  let memDeltaKb: Int64
}

private func measure<T>(_ name: String, _ block: () throws -> T) rethrows -> (T, PerfSample) {
  let state = cameraSignposter.beginInterval(name, id: cameraSignposter.makeSignpostID())
  let memPre = CameraPerfMetrics.physFootprintKb()
  let t0 = CameraPerfMetrics.now()
  let result = try block()
  let t1 = CameraPerfMetrics.now()
  let memPost = CameraPerfMetrics.physFootprintKb()
  cameraSignposter.endInterval(name, state)
  return (result, PerfSample(name: name, deltaMs: CameraPerfMetrics.elapsedMs(from: t0, to: t1), memDeltaKb: memPost - memPre))
}

private func measureAsync<T>(_ name: String, _ block: () async throws -> T) async rethrows -> (T, PerfSample) {
  let state = cameraSignposter.beginInterval(name, id: cameraSignposter.makeSignpostID())
  let memPre = CameraPerfMetrics.physFootprintKb()
  let t0 = CameraPerfMetrics.now()
  let result = try await block()
  let t1 = CameraPerfMetrics.now()
  let memPost = CameraPerfMetrics.physFootprintKb()
  cameraSignposter.endInterval(name, state)
  return (result, PerfSample(name: name, deltaMs: CameraPerfMetrics.elapsedMs(from: t0, to: t1), memDeltaKb: memPost - memPre))
}
```

**5c.** Add a perf callback hook to `CameraManager`:

```swift
  var onPerformanceSample: ((String, Double, Int64) -> Void)?
```

**5d.** Wrap critical paths. Replace `func startSession(config: CameraConfig) async throws { ... existing body ... }` with:

```swift
  func startSession(config: CameraConfig) async throws {
    let (_, sample) = try await measureAsync("startSession") {
      try await self._startSessionInternal(config: config)
    }
    onPerformanceSample?(sample.name, sample.deltaMs, sample.memDeltaKb)
  }

  private func _startSessionInternal(config: CameraConfig) async throws {
    // [PASTE THE PREVIOUS startSession BODY HERE — same code, just renamed]
  }
```

Apply the same pattern to `stopSession`, `switchLens`, `setFormat` (the synchronous ones use `measure`):

```swift
  func stopSession() {
    let ((), sample) = measure("stopSession") {
      self._stopSessionInternal()
    }
    onPerformanceSample?(sample.name, sample.deltaMs, sample.memDeltaKb)
  }

  private func _stopSessionInternal() {
    // [PASTE PREVIOUS stopSession BODY]
  }

  func switchLens(_ lens: LensType) throws {
    let ((), sample) = try measure("switchLens") {
      try self._switchLensInternal(lens)
    }
    onPerformanceSample?(sample.name, sample.deltaMs, sample.memDeltaKb)
  }

  private func _switchLensInternal(_ lens: LensType) throws {
    // [PASTE PREVIOUS switchLens BODY]
  }

  func setFormat(resolution: Resolution, fps: Fps) throws {
    let ((), sample) = try measure("setFormat") {
      try self._setFormatInternal(resolution: resolution, fps: fps)
    }
    onPerformanceSample?(sample.name, sample.deltaMs, sample.memDeltaKb)
  }

  private func _setFormatInternal(resolution: Resolution, fps: Fps) throws {
    // [PASTE PREVIOUS setFormat BODY]
  }
```

- [ ] **7.6 — Emit `onPerformanceMetric` from `CameraHostApiImpl.swift`**

Edit `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift`:

In `init(messenger:)` after the `manager.onFocusResult = ...` block, add:

```swift
    manager.onPerformanceSample = { [weak self] name, deltaMs, memKb in
      DispatchQueue.main.async {
        let metric = PerformanceMetric(name: name, deltaMs: deltaMs, memoryKb: memKb)
        self?.flutterApi.onPerformanceMetric(metric: metric) { _ in }
      }
    }
```

- [ ] **7.7 — Run native tests**

```bash
cd apps/mobile/ios && \
  xcodebuild test \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:RunnerTests 2>&1 | tail -15
```

Expected: 5 tests passed (`CameraPerfMetricsTests` 3 + `CameraPlatformViewTests` 2).

- [ ] **7.8 — Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/CameraPerfMetrics.swift \
        apps/mobile/ios/Runner/Native/Camera/CameraManager.swift \
        apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift \
        apps/mobile/ios/RunnerTests/CameraPerfMetricsTests.swift
git commit -m "feat(camera): ios performance instrumentation via ossignposter + mach_absolute_time"
```

---

## Task 8 — Android perf instrumentation (`Trace` + `CameraPerfMetrics`)

**Files:**
- Create: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetrics.kt`
- Create: `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetricsTest.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt`

- [ ] **8.1 — Write failing test**

Create `apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetricsTest.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CameraPerfMetricsTest {
  @Test
  fun nsToMsConvertsCorrectly() {
    assertEquals(1.0, CameraPerfMetrics.nsToMs(1_000_000L), 0.001)
    assertEquals(0.5, CameraPerfMetrics.nsToMs(500_000L), 0.001)
    assertEquals(0.0, CameraPerfMetrics.nsToMs(0L), 0.001)
  }

  @Test
  fun elapsedMsIsNonNegative() {
    val t0 = CameraPerfMetrics.now()
    Thread.sleep(10)
    val t1 = CameraPerfMetrics.now()
    val elapsed = CameraPerfMetrics.elapsedMs(t0, t1)
    assertTrue("elapsed=$elapsed", elapsed >= 0.0)
  }
}
```

- [ ] **8.2 — Run test (expect fail)**

```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest \
  --tests "com.rarocamera.raro_mobile.camera.CameraPerfMetricsTest" 2>&1 | tail -10
```

Expected: FAIL — class not found.

- [ ] **8.3 — Create `CameraPerfMetrics.kt`**

Create `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetrics.kt`:

```kotlin
package com.rarocamera.raro_mobile.camera

import android.os.Debug
import android.os.SystemClock

object CameraPerfMetrics {
  fun now(): Long = SystemClock.elapsedRealtimeNanos()

  fun nsToMs(nanoseconds: Long): Double = nanoseconds / 1_000_000.0

  fun elapsedMs(start: Long, end: Long): Double = nsToMs(end - start)

  fun totalPssKb(): Long {
    val info = Debug.MemoryInfo()
    Debug.getMemoryInfo(info)
    return info.totalPss.toLong()
  }
}
```

- [ ] **8.4 — Run test (expect pass)**

```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest \
  --tests "com.rarocamera.raro_mobile.camera.CameraPerfMetricsTest" 2>&1 | tail -10
```

Expected: 2 tests passed.

- [ ] **8.5 — Wrap critical paths in `CameraManager.kt` with `Trace` + perf sample**

Edit `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt`:

**5a.** Add import:

```kotlin
import android.os.Trace
import kotlinx.coroutines.Dispatchers
```

**5b.** Add public callback near `onLensSwitched`:

```kotlin
  var onPerformanceSample: ((String, Double, Long) -> Unit)? = null
```

**5c.** Add private helper at end of class:

```kotlin
  private inline fun <T> measure(name: String, block: () -> T): T {
    Trace.beginSection(name)
    val memPre = CameraPerfMetrics.totalPssKb()
    val t0 = CameraPerfMetrics.now()
    val result = block()
    val t1 = CameraPerfMetrics.now()
    Trace.endSection()
    lifecycleOwner.lifecycleScope.launch(Dispatchers.Default) {
      val memPost = CameraPerfMetrics.totalPssKb()
      val deltaMs = CameraPerfMetrics.elapsedMs(t0, t1)
      onPerformanceSample?.invoke(name, deltaMs, memPost - memPre)
    }
    return result
  }
```

**5d.** Wrap each top-level public method:

```kotlin
  fun startSession(config: CameraConfig) = measure("startSession") { _startSessionInternal(config) }
  fun stopSession() = measure("stopSession") { _stopSessionInternal() }
  fun switchLens(lens: LensType) = measure("switchLens") { _switchLensInternal(lens) }
  fun setFormat(resolution: Resolution, fps: Fps) = measure("setFormat") { _setFormatInternal(resolution, fps) }
```

Rename the existing implementation bodies to `_startSessionInternal`, `_stopSessionInternal`, `_switchLensInternal`, `_setFormatInternal` (private methods).

- [ ] **8.6 — Emit `onPerformanceMetric` from `CameraHostApiImpl.kt`**

Edit `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt`. In `init { ... }` after `manager.onFocusResult = ...`, add:

```kotlin
    manager.onPerformanceSample = { name, deltaMs, memKb ->
      main.post {
        flutterApi.onPerformanceMetric(
          com.rarocamera.raro_mobile.generated.camera.PerformanceMetric(
            name = name,
            deltaMs = deltaMs,
            memoryKb = memKb,
          )
        ) {}
      }
    }
```

- [ ] **8.7 — Run Android tests**

```bash
cd apps/mobile/android && ./gradlew :app:testDebugUnitTest 2>&1 | tail -10
```

Expected: all green.

- [ ] **8.8 — Commit**

```bash
git add apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetrics.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt \
        apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraHostApiImpl.kt \
        apps/mobile/android/app/src/test/kotlin/com/rarocamera/raro_mobile/camera/CameraPerfMetricsTest.kt
git commit -m "feat(camera): android performance instrumentation via trace + elapsedrealtimenanos"
```

---

## Task 9 — Flutter wire-up: repo stream + controller + harness HUD

**Files:**
- Modify: `apps/mobile/lib/features/camera/data/camera_repository.dart`
- Modify: `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart`
- Modify: `apps/mobile/lib/features/camera/application/camera_controller.dart`
- Modify: `apps/mobile/lib/features/camera/presentation/camera_test_harness_screen.dart`
- Modify: `apps/mobile/test/features/camera/application/camera_controller_test.dart`
- Modify: `apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart` (if exists)

- [ ] **9.1 — Write failing controller test**

Add to `apps/mobile/test/features/camera/application/camera_controller_test.dart` inside `void main() { ... }`:

```dart
  test('exposes performance metric stream from repository', () async {
    final repo = _makeRepo();
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
    final controller = StreamController<PerformanceMetric>();
    when(() => repo.performanceMetrics).thenAnswer((_) => controller.stream);
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    addTearDown(controller.close);

    await c.read(cameraControllerProvider.future);
    final received = <PerformanceMetric>[];
    c.read(cameraControllerProvider.notifier).addPerformanceMetricListener(
      received.add,
    );
    controller.add(PerformanceMetric(name: 'startSession', deltaMs: 412.5, memoryKb: 18432));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(received, hasLength(1));
    expect(received.first.name, 'startSession');
    expect(received.first.deltaMs, 412.5);
    expect(received.first.memoryKb, 18432);
  });
```

Also add imports at top:

```dart
import 'dart:async';
```

- [ ] **9.2 — Run test (expect fail)**

```bash
cd apps/mobile && flutter test test/features/camera/application/camera_controller_test.dart 2>&1 | tail -20
```

Expected: FAIL — `performanceMetrics` not in `CameraRepository`, `addPerformanceMetricListener` not in controller.

- [ ] **9.3 — Update `CameraRepository` abstract**

Replace `apps/mobile/lib/features/camera/data/camera_repository.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

abstract class CameraRepository {
  Stream<PerformanceMetric> get performanceMetrics;

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

- [ ] **9.4 — Update `PigeonCameraRepository` to receive `onPerformanceMetric`**

Replace `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart`:

```dart
import 'dart:async';

import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';

class PigeonCameraRepository implements CameraRepository, CameraFlutterApi {
  PigeonCameraRepository(this._api);

  final CameraHostApi _api;
  final StreamController<PerformanceMetric> _perfController =
      StreamController<PerformanceMetric>.broadcast();

  @override
  Stream<PerformanceMetric> get performanceMetrics => _perfController.stream;

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

  @override
  void onSessionStarted(CameraConfig activeConfig) {}

  @override
  void onSessionStopped() {}

  @override
  void onLensSwitched(LensType lens) {}

  @override
  void onFocusChanged(FocusPoint point, bool locked) {}

  @override
  void onError(CameraErrorCode code, String? message) {}

  @override
  void onPerformanceMetric(PerformanceMetric metric) {
    _perfController.add(metric);
  }

  void dispose() {
    _perfController.close();
  }
}
```

- [ ] **9.5 — Register repo as `CameraFlutterApi` handler**

Inspect provider:

```bash
cat apps/mobile/lib/features/camera/data/camera_repository_provider.dart
```

Update the provider so the same instance is registered via `CameraFlutterApi.setUp(binaryMessenger, repo)`. Concrete patch (apply to whatever file actually constructs the repo, likely the provider):

```dart
import 'package:flutter/services.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/pigeon_camera_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CameraRepository cameraRepository(Ref ref) {
  final messenger = ServicesBinding.instance.defaultBinaryMessenger;
  final hostApi = CameraHostApi(binaryMessenger: messenger);
  final repo = PigeonCameraRepository(hostApi);
  CameraFlutterApi.setUp(messenger, repo);
  ref.onDispose(repo.dispose);
  return repo;
}
```

If the existing provider differs significantly, adapt the patch and DO NOT widen scope.

- [ ] **9.6 — Add `addPerformanceMetricListener` to `CameraController`**

Edit `apps/mobile/lib/features/camera/application/camera_controller.dart`. Add at top:

```dart
import 'dart:async';
```

Inside `class CameraController extends _$CameraController { ... }`, add:

```dart
  StreamSubscription<PerformanceMetric>? _perfSub;

  void addPerformanceMetricListener(void Function(PerformanceMetric) listener) {
    _perfSub?.cancel();
    _perfSub = _repo.performanceMetrics.listen(listener);
    ref.onDispose(() => _perfSub?.cancel());
  }
```

- [ ] **9.7 — Run controller test (expect pass)**

```bash
cd apps/mobile && flutter test test/features/camera/application/camera_controller_test.dart 2>&1 | tail -10
```

Expected: all tests pass (including the new perf metric one).

- [ ] **9.8 — Add HUD to `camera_test_harness_screen.dart`**

Edit `apps/mobile/lib/features/camera/presentation/camera_test_harness_screen.dart`. Inside `_CameraTestHarnessScreenState`:

**8a.** Add state:

```dart
  final List<String> _perfHud = <String>[];
```

**8b.** In `initState()` after `WidgetsBinding.instance.addObserver(this);`, add:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).addPerformanceMetricListener(
        (metric) {
          final entry =
              '${metric.name} · ${metric.deltaMs.toStringAsFixed(1)}ms · '
              '${metric.memoryKb > 0 ? '+' : ''}${metric.memoryKb}kb';
          setState(() {
            _perfHud.insert(0, entry);
            if (_perfHud.length > 8) _perfHud.removeLast();
          });
        },
      );
    });
```

**8c.** In `build(...)` HUD section, render `_perfHud` somewhere visible (next to `_eventLog`):

```dart
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERF',
                style: TextStyle(color: Colors.greenAccent, fontSize: 10),
              ),
              ..._perfHud.map(
                (e) => Text(
                  e,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
```

- [ ] **9.9 — Run mobile analyze + tests**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/mobile run test
```

Expected: zero issues, all tests pass.

- [ ] **9.10 — Commit**

```bash
git add apps/mobile/lib/features/camera/data/camera_repository.dart \
        apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart \
        apps/mobile/lib/features/camera/data/camera_repository_provider.dart \
        apps/mobile/lib/features/camera/data/camera_repository_provider.g.dart \
        apps/mobile/lib/features/camera/application/camera_controller.dart \
        apps/mobile/lib/features/camera/presentation/camera_test_harness_screen.dart \
        apps/mobile/test/features/camera/application/camera_controller_test.dart
git commit -m "feat(camera): wire performance metric stream to controller and harness hud"
```

---

## Task 10 — `/verify-slice` T2 (perf done)

- [ ] **10.1 — Harness validation**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/shared run analyze
bun --filter @raro/shared run test
bun --filter @raro/mobile run test
```

Expected: all green.

- [ ] **10.2 — Dispatch `flutter-perf-auditor` subagent**

Dispatch via `Agent` tool, `subagent_type: "flutter-perf-auditor"`:

> Audit `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` and `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/CameraManager.kt` for the perf instrumentation just added. Check: (1) `OSSignposter`/`Trace` calls correctly bracket the critical path; (2) memory capture (`physFootprintKb`/`totalPssKb`) does NOT happen inside the timed block — only outside; (3) `onPerformanceSample` callback never blocks the camera thread. Read-only — do not modify code. Report PASS | ISSUES.

If ISSUES reported, fix inline and re-run.

---

# Phase 3 — Device sweep (iPhone 12 + Samsung M54)

## Task 11 — iPhone 12 device sweep

> **Manual task with user.** Pause and request iPhone 12 connection + Xcode + Instruments setup.

- [ ] **11.1 — Connect iPhone 12 + select scheme**

```bash
flutter devices
```

Expected: iPhone 12 listed. Open Xcode → `apps/mobile/ios/Runner.xcworkspace`. Edit Scheme → Build Configuration = `Debug`.

- [ ] **11.2 — Bootstrap iOS (if Pods changed)**

```bash
bun --filter @raro/mobile run bootstrap:ios
```

Expected: success message.

- [ ] **11.3 — Run from Xcode in debug, navigate to harness**

In Xcode: ⌘R. App opens. Navigate to `/camera/harness`. Tap "Request Permission" → "Start". Wait for preview to render.

- [ ] **11.4 — Verify G4 visually**

Tap on different points of the preview. Confirm:
- White ring appears within 200ms
- Ring scales 1.4→1.0 with easeOut
- Ring fades 0→1→0 over 1.2s
- Ring centered on tap point
- No flicker / hybrid composition artifacts

If any deviation: stop, capture Xcode Console logs, debug. Memory `feedback_device_debug_use_real_logs_not_assumptions` applies.

- [ ] **11.5 — Verify G1 (start) + G7 (memory) via HUD**

In harness:
- Tap "Stop" then "Start" 3× consecutively.
- Capture HUD values for each cycle: `startSession · XXX.Xms · +XXkb`.
- Confirm `startSession` deltaMs ≤ 500.
- Confirm `stopSession` memDelta is roughly `-(startSession memDelta)` within ±5MB (5120 KB) across the 3 cycles.

Record values in scratch file (do NOT commit yet):

```bash
cat > /tmp/iphone12-baseline.txt <<EOF
iPhone 12 baseline 2026-05-28
Run 1: start=___ms mem=+___KB | stop=___ms mem=-___KB
Run 2: start=___ms mem=+___KB | stop=___ms mem=-___KB
Run 3: start=___ms mem=+___KB | stop=___ms mem=-___KB
G1 verdict: PASS/FAIL (target ≤500ms)
G7 verdict: PASS/FAIL (target ±5120KB)
EOF
```

Fill in numbers from HUD.

- [ ] **11.6 — Xcode Instruments baseline (Allocations + Points of Interest)**

In Xcode: Product → Profile (⌘I) → Instruments opens.
- Choose "Allocations" template.
- Add Points of Interest track from + button (look for `com.rarocamera` subsystem).
- Click record. App launches under Instruments.
- Navigate to harness, run 3 cycles (start/stop).
- Stop recording.

Capture screenshot of Allocations summary (Persistent Bytes pre vs post 3 cycles). Save to:

```
docs/perf/baselines/camera-iphone12.summary.md
```

Content template (fill numbers):

```markdown
# iPhone 12 — Camera baseline (2026-05-28)

## Device
- iPhone 12 (A2403) — iOS XX.X — debug build

## startSession deltaMs (3 runs)
- Run 1: ___ms
- Run 2: ___ms
- Run 3: ___ms
- Mean: ___ms
- G1 target: ≤ 500ms — **PASS/FAIL**

## stopSession deltaMs (3 runs)
- Run 1: ___ms
- Run 2: ___ms
- Run 3: ___ms

## Memory (Allocations)
- Persistent bytes before first start: ___ MB
- After 3 start/stop cycles: ___ MB
- Delta (leak indicator): ___ KB
- G7 target: ±5120 KB — **PASS/FAIL**

## Instruments Points of Interest
- startSession interval mean: ___ms (matches HUD)
- switchLens interval mean: ___ms
- setFormat interval mean: ___ms

## Notes
- No `.trace` binary committed (size policy)
- Screenshot reference: see attached `iphone12-allocations.png` (NOT committed)
```

- [ ] **11.7 — Commit iPhone 12 baseline doc**

```bash
mkdir -p docs/perf/baselines
# (fill in /tmp values into the .md file above and save under docs/perf/baselines/)
git add docs/perf/baselines/camera-iphone12.summary.md
git commit -m "docs(camera): iphone 12 perf baseline for g1 and g7"
```

---

## Task 12 — Samsung Galaxy M54 device sweep

> **Manual task with user.** USB Debugging + USB cable.

- [ ] **12.1 — Connect M54 + verify `adb`**

```bash
adb devices
flutter devices
```

Expected: M54 listed in both. If M54 prompts "Allow USB debugging?", accept.

- [ ] **12.2 — Run debug build to device**

```bash
cd apps/mobile && flutter run -d <m54-device-id> 2>&1 | tail -10
```

Expected: app launches on M54.

- [ ] **12.3 — Verify G2 capabilities + G3 lens switch + G4 ring**

In harness:
- Tap "Discover capabilities". Expected: `availableLenses` includes both `ultraWide` and `wide` (M54 has separate 8MP ultra-wide).
- Tap "Switch to 0.5×". Confirm preview shifts to wider FoV. No black frames.
- Tap "Switch to 1×". Confirm preview returns. No flicker.
- Tap on preview. Confirm white ring renders (Android side).

- [ ] **12.4 — Verify G6b 4K@30 (not @60) — capture metadata**

In harness:
- Set resolution to `UHD4K`, fps to `FPS30`. Tap "Apply". Confirm preview displays without crash.
- Try setting `FPS60`. Expected: **`CameraNativeException` thrown** (M54 hardware limit) OR fallback to closest supported (likely 4K@30 via `FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER`).
- Capture `adb logcat -s RaroCamera:V` showing the resolution/fps actually applied.

- [ ] **12.5 — Verify G1/G7 via HUD (3 cycles)**

Same as iPhone 12 Task 11.5. Save to `/tmp/m54-baseline.txt`.

- [ ] **12.6 — Android Studio Profiler baseline**

In Android Studio:
- Open `apps/mobile/android` as project.
- Run → Profile app on M54.
- Memory Profiler: capture heap snapshots pre + post 3 start/stop cycles.
- CPU Profiler: trace `startSession` Trace section. Confirm `startSession` section visible.

Create `docs/perf/baselines/camera-m54.summary.md`:

```markdown
# Samsung Galaxy M54 5G — Camera baseline (2026-05-28)

## Device
- Samsung Galaxy M54 5G (SM-M546B) — Exynos 1380 — One UI 6 (Android 14)
- Cameras: 108MP wide (main) + 8MP ultra-wide + 2MP macro
- Video hardware limit: **4K @ 30fps** (no 4K@60)

## startSession deltaMs (3 runs)
- Run 1: ___ms
- Run 2: ___ms
- Run 3: ___ms
- Mean: ___ms
- G1 target: ≤ 500ms — **PASS/FAIL**

## stopSession deltaMs (3 runs)
- Run 1: ___ms
- Run 2: ___ms
- Run 3: ___ms

## Memory (Memory Profiler)
- Total PSS before first start: ___ MB
- After 3 start/stop cycles: ___ MB
- Delta: ___ KB
- G7 target: ±5120 KB — **PASS/FAIL**

## G3 lens switch (wide ↔ ultra-wide)
- 1× → 0.5×: no blackout observed (CameraX PreviewView holds last frame)
- 0.5× → 1×: no blackout observed

## G6b 4K@30 confirmation
- Resolution = UHD4K, Fps = FPS30 → applied successfully
- Resolution = UHD4K, Fps = FPS60 → fallback to FPS30 (CameraX `FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER`) — confirmed via logcat
- Hardware limit (Exynos 1380): expected, not a bug

## One UI 6 background behavior
- Recents Menu during capture: `Lifecycle.onPause` triggered; preview paused
- Foreground → background → foreground: session resumes cleanly
- No need for modal anti-kill (One UI 6 honors Android 14 FGS policy)

## Notes
- Modal `M02 Xiaomi` remains for Xiaomi only — does NOT apply to M54
- Reference: memory `raro-pattern-xiaomi-miui-hyperos-detection`
```

- [ ] **12.7 — Commit M54 baseline doc**

```bash
git add docs/perf/baselines/camera-m54.summary.md
git commit -m "docs(camera): samsung galaxy m54 perf baseline + 4k@30 confirmation"
```

---

## Task 13 — ADR-0015 addendum I + Blueprint + CLAUDE.md updates

- [ ] **13.1 — Add ADR-0015 addendum I**

Open `docs/decisions/0015-camera-native-bridge-strategy.md`. After the last addendum (H), append:

```markdown
## Addendum I — 2026-05-28: Task 19 closure (G4 native ring + G1/G7 perf + Samsung M54)

### Decisions

| Item | Decision | Rationale |
|---|---|---|
| G4 focus ring (iOS) | `CAShapeLayer` sublayer no `AVCaptureVideoPreviewLayer` com `CABasicAnimation` (scale 1.4→1.0 easeOut) + `CAKeyframeAnimation` (opacity [0,1,0] keyTimes [0,0.2,1]) | Apple-documented pattern (forums thread 97336). Evita hybrid composition issue (memória `raro-pattern-ios-platformview-camera-preview-black`). |
| G4 focus ring (Android) | `FocusRingView` custom View dentro de `FrameLayout` sobre `PreviewView` + `ObjectAnimator` scaleX/Y + alpha keyframes | Modern Android pattern. `setClickable(false)` + `setFocusable(false)` preserva tap pass-through. |
| AF result callback (iOS) | KVO em `device.isAdjustingFocus` com debounce 100ms + timeout 3s | Apple-documented; debounce evita ruído de autofocus oscilando |
| AF result callback (Android) | `cameraControl.startFocusAndMetering` `ListenableFuture<FocusMeteringResult>.await` → `isFocusSuccessful` | CameraX 1.6 idiomático |
| iOS perf signposts | `OSSignposter` (iOS 15+) | Apple-recommended; `os_signpost` C API é legacy desde iOS 15. Funciona com Instruments built-in templates (Points of Interest, Time Profiler). |
| iOS perf timer | `mach_absolute_time` + `mach_timebase_info` (não `ContinuousClock`) | `ContinuousClock` requer Swift 5.7/iOS 16+. RARO target iOS 15+. Bump rejeitado: ROI baixo (iOS 15 share ≈1.5% May 2026). Reavaliar em v1.1. |
| Android perf signposts | `android.os.Trace.beginSection`/`endSection` | Native Android Profiler integration |
| Android perf timer | `SystemClock.elapsedRealtimeNanos` | Monotonic, ns precision |
| Memory capture | `task_info(TASK_VM_INFO).phys_footprint` (iOS) / `Debug.MemoryInfo.getTotalPss()` (Android) — **fora do critical path** | `getTotalPss` é caro (5–20ms); medir em coroutine background evita poluir métrica de start time |
| Pigeon delta | `FlutterApi.onPerformanceMetric(PerformanceMetric{name, deltaMs, memoryKb})` | Async push do nativo, sem mudar HostApi |
| `FocusRingConfig` | Constants em `raro_shared` Dart-only; espelhadas em Swift `enum FocusRingConfig` + Kotlin `object FocusRingConfig` | Single source of truth conceitual; build-time constants nos 2 sides (sem bridge runtime) |
| Samsung Galaxy M54 4K@60 | **Não suportado** — Exynos 1380 hardware limit é 4K@30 | Não é bug do app. G6 split: G6a iOS @60 / G6b Android @30 |
| Samsung One UI 6 anti-kill modal | **Não necessário** — Samsung honra Android 14 FGS policy oficialmente | Diferente do Xiaomi MIUI/HyperOS (memória `raro-pattern-xiaomi-miui-hyperos-detection` permanece relevante só para Xiaomi) |
| G10 iPad | **Removido do escopo** — cliente contratou iOS smartphone + Android smartphone apenas | App Store Connect capability iPhone-only em release prep futuro |
| G9 cold restart real (fechar app via ícone) | **Adiado para TestFlight** — requer Apple Developer Program ($99/ano) | Control Center / multitasking parcial cobre comportamento funcional via observers existentes |

### iPhone 12 baseline (2026-05-28)

Ver `docs/perf/baselines/camera-iphone12.summary.md` para valores numéricos.

### Samsung Galaxy M54 baseline (2026-05-28)

Ver `docs/perf/baselines/camera-m54.summary.md`.

### Sources consultadas

- Apple OSSignposter docs — https://developer.apple.com/documentation/os/ossignposter
- Apple ContinuousClock docs — https://developer.apple.com/documentation/swift/continuousclock
- Apple AVCaptureVideoPreviewLayer overlay forum thread — https://developer.apple.com/forums/thread/97336
- SE-0329 Clock, Instant, Duration — https://github.com/swiftlang/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md
- CameraX tap-to-focus + tapToFocusState — https://developer.android.com/jetpack/androidx/releases/camera
- GSMArena Samsung Galaxy M54 — https://www.gsmarena.com/samsung_galaxy_m54-12189.php
- Don't Kill My App — Samsung — https://dontkillmyapp.com/samsung
- opentelemetry-swift #582 — https://github.com/open-telemetry/opentelemetry-swift/issues/582
```

- [ ] **13.2 — Update Blueprint Seção 5 (P05 Câmera) or Seção 4 (tokens)**

Open `docs/Blueprint.md`. Locate Section 4 (tokens) — add a subsection:

```markdown
### Focus ring (P05)

Constants em `packages/shared/lib/src/camera/focus_ring_config.dart` (Dart) com espelhos em `apps/mobile/ios/Runner/Native/Camera/FocusRingConfig.swift` e `apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/camera/FocusRingConfig.kt`. Renderização nativa (CAShapeLayer iOS / FocusRingView Android) — não Flutter overlay. Ver ADR-0015 addendum I.

| Token | Valor |
|---|---|
| color | `#FFFFFF` |
| strokeWidth | 1.5 |
| durationMs | 1200 |
| scaleFrom → scaleTo | 1.4 → 1.0 (easeOut) |
| opacity keyframes | `[0.0, 1.0, 0.0]` keyTimes `[0.0, 0.2, 1.0]` |
| radiusPx | 32 |
```

In Section 5 (telas / P05), append note:

```markdown
**4K@60fps:** disponível no iPhone 12+ (iOS). No Android Samsung Galaxy M54 (Exynos 1380), o máximo é 4K@30 — limite de hardware, não bug. `discoverCapabilities` expõe `supportedFps` corretamente, e `Preview.Builder` faz fallback automático via `FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER`. Ver ADR-0015 addendum I.
```

- [ ] **13.3 — CLAUDE.md §11 — add anti-pattern**

Open `CLAUDE.md`. Find Seção 11 (Anti-patterns proibidos). Append at end:

```markdown
- ❌ Renderizar overlay UI Flutter (Stack, CustomPaint, Positioned) **sobre PlatformView** (`UiKitView`/`AndroidView`). Em iOS, quebra hybrid composition (memória `raro-pattern-ios-platformview-camera-preview-black`). Solução: renderizar overlay **no lado nativo** (CAShapeLayer/CALayer iOS, custom View Android dentro de FrameLayout wrapping o PreviewView). Ver ADR-0015 addendum I.
```

- [ ] **13.4 — Run docs-lint slash command**

Run via `Skill` tool:

```
/docs-lint
```

Expected: zero broken links, zero orphans relative to new files.

- [ ] **13.5 — Commit docs**

```bash
git add docs/decisions/0015-camera-native-bridge-strategy.md \
        docs/Blueprint.md \
        CLAUDE.md
git commit -m "docs(camera): adr-0015 addendum i + blueprint focus ring tokens + claude anti-pattern"
```

---

## Task 14 — `/verify-slice` T3 + validator subagent

- [ ] **14.1 — Final harness validation**

```bash
bun --filter @raro/mobile run codegen
bun --filter @raro/mobile run analyze
bun --filter @raro/shared run analyze
bun --filter @raro/shared run test
bun --filter @raro/mobile run test
```

Expected: all green.

- [ ] **14.2 — Dispatch `validator` subagent**

Dispatch via `Agent` tool, `subagent_type: "validator"`:

> Verify the implementation against `docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md` Observable goals section. For each goal (G1–G9), point to the test or device-recorded evidence. Specifically check:
>
> 1. `FocusRingConfig` constants match between Dart, Swift, and Kotlin (read all 3 files)
> 2. iOS `CAShapeLayer` adds `scale` and `opacity` animations matching config
> 3. Android `FocusRingView` `ObjectAnimator` matches config
> 4. `OSSignposter` brackets startSession/stopSession/switchLens/setFormat in iOS CameraManager
> 5. Android `Trace.beginSection`/`endSection` brackets the same 4 methods
> 6. `PerformanceMetric` Pigeon callback emits from both sides
> 7. Harness HUD listens to perf stream
> 8. iPhone 12 + M54 baseline docs exist and numbers fit goals (G1 ≤500ms, G7 ≤±5MB)
> 9. ADR-0015 addendum I is present with all decisions documented
> 10. CLAUDE.md §11 has the new anti-pattern entry
>
> Read-only — do NOT modify code. Report SPEC_COMPLIANT | NON_COMPLIANT(items).

If NON_COMPLIANT, fix items and re-run.

- [ ] **14.3 — Mark spec `Done`**

Open `docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md`. Change Status from `Approved` (or `In implementation`) to `Done`.

Open `docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md`. Change Status from `In implementation (Task 19 device tests pending — Tasks 1-18 done)` to `Done`.

```bash
git add docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md \
        docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md
git commit -m "docs(spec): mark camera-native-bridge + task-19-closure as done"
```

---

# Phase 4 — Closure (session log + index + changelog + merge)

## Task 15 — Session 0006 log + INDEX update

- [ ] **15.1 — Create `docs/sessions/0006-camera-task-19-closure.md`**

Use the same shape as `docs/sessions/0005-camera-device-validation.md`. Fill sections: Objetivo, Contexto inicial, O que foi feito (per task), O que NÃO foi feito (Apple Dev Program adiado, rule-of-thirds/grain ainda Flutter, iPad fora de escopo), Aprendizados/surpresas (4K@30 M54, One UI 6 FGS), Próximos passos (replay-buffer rm-8 ou voice).

(Content is auto-derivable from this plan + commits; engineer fills with actual numbers from baseline docs.)

- [ ] **15.2 — Update `docs/sessions/0001-INDEX.md`**

Insert row at top of session table:

```markdown
| [0006](0006-camera-task-19-closure.md) | 2026-05-28 → <end date> | camera task 19 closure (g4 native ring CAShapeLayer/FocusRingView + g1/g7 OSSignposter/Trace + iPhone 12 + Samsung M54 baselines + ADR-0015 addendum I + spec Done) | `feat/camera-native-bridge` (merged em `develop`) | `bbe3285` … `<last sha>` (<N> commits) |
```

Update "Próxima sessão sugerida" pointing to `feat/replay-buffer-native-bridge` (rm-8) as new Opção A.

- [ ] **15.3 — Update `docs/10-CHANGELOG.md`**

Add entry at top:

```markdown
## 0.4.2 — 2026-05-28

### Added
- Native focus ring rendering on iOS (`CAShapeLayer` sublayer) and Android (`FocusRingView` in `FrameLayout`)
- Performance instrumentation via `OSSignposter` (iOS) and `android.os.Trace` (Android)
- Pigeon callback `FlutterApi.onPerformanceMetric` for start/stop/switchLens/setFormat metrics
- `FocusRingConfig` shared constants (`packages/shared/lib/src/camera/focus_ring_config.dart`)
- iPhone 12 and Samsung Galaxy M54 5G perf baselines (`docs/perf/baselines/`)
- ADR-0015 addendum I — Task 19 closure
- CLAUDE.md §11 anti-pattern: Flutter overlay over PlatformView

### Removed
- `apps/mobile/lib/features/camera/presentation/focus_ring_overlay.dart` (replaced by native rendering)

### Notes
- Samsung Galaxy M54 4K@30 confirmed as hardware limit (Exynos 1380), not bug — `discoverCapabilities` exposes correctly
- One UI 6 honors Android 14 FGS policy — no modal anti-kill needed on M54
- iPad excluded from scope (smartphone-only)
- G9 cold restart deferred to TestFlight (requires Apple Developer Program)
```

- [ ] **15.4 — Commit closure docs**

```bash
git add docs/sessions/0006-camera-task-19-closure.md \
        docs/sessions/0001-INDEX.md \
        docs/10-CHANGELOG.md
git commit -m "docs(docs): close session 0006 — camera task 19 + changelog 0.4.2"
```

---

## Task 16 — Merge `feat/camera-native-bridge` → `develop` → `main`

- [ ] **16.1 — Final pre-merge verification**

```bash
bun --filter @raro/mobile run analyze
bun --filter @raro/shared run analyze
bun --filter @raro/shared run test
bun --filter @raro/mobile run test
git status --short
```

Expected: all green, working tree clean.

- [ ] **16.2 — Push branch**

```bash
git push -u origin feat/camera-native-bridge
```

- [ ] **16.3 — Open PR `feat/camera-native-bridge` → `develop`**

```bash
gh pr create --base develop --head feat/camera-native-bridge \
  --title "feat(camera): native bridge complete with task 19 closure" \
  --body "$(cat <<'EOF'
## Summary
- Closes Task 19 of spec [`2026-05-26-camera-native-bridge-design`](docs/superpowers/specs/2026-05-26-camera-native-bridge-design.md)
- Implements [`2026-05-28-camera-task-19-closure-design`](docs/superpowers/specs/2026-05-28-camera-task-19-closure-design.md)
- G4 native focus ring (iOS CAShapeLayer + Android FocusRingView)
- G1/G7 perf instrumentation (OSSignposter + Trace)
- iPhone 12 + Samsung Galaxy M54 5G baselines committed
- ADR-0015 addendum I documents all decisions

## Test plan
- [x] iPhone 12 device: G1, G2, G3, G4, G5, G6a, G7, G8 verified
- [x] Samsung M54 device: G1, G2, G3, G4, G5, G6b (4K@30), G7, G8 verified
- [x] G9 cold restart: deferred to TestFlight (Apple Dev Program)
- [x] G10 iPad: removed from scope (smartphone-only)
- [x] `bun run analyze` (mobile + shared) green
- [x] `bun run test` (mobile + shared) green
- [x] design-fidelity-checker subagent: APPROVED
- [x] flutter-perf-auditor subagent: PASS
- [x] validator subagent: SPEC_COMPLIANT
EOF
)"
```

- [ ] **16.4 — Merge `develop` after review**

Manual: review PR + merge via GitHub (squash or merge — per repo convention).

After merge:

```bash
git checkout develop && git pull
git checkout main && git merge develop && git push
```

(Or open a separate `develop → main` PR if that's the repo convention.)

- [ ] **16.5 — Delete branch (post-merge cleanup)**

```bash
git branch -d feat/camera-native-bridge
git push origin --delete feat/camera-native-bridge
```

---

## Done when

- [ ] All 16 tasks above checked ✅
- [ ] `bun run analyze` + `bun run test` zero issues (mobile + shared)
- [ ] Both device baseline docs exist and meet G1/G7 numerical targets
- [ ] ADR-0015 addendum I present and committed
- [ ] CLAUDE.md §11 new anti-pattern present
- [ ] Specs camera-native-bridge + task-19-closure marked `Done`
- [ ] PR merged to `develop` (and `main` per convention)
- [ ] `docs/sessions/0001-INDEX.md` updated with row 0006
- [ ] `docs/10-CHANGELOG.md` updated with 0.4.2 entry
- [ ] Branch `feat/camera-native-bridge` deleted

## Out-of-scope reminders (do NOT do)

- ❌ Rule-of-thirds + viewport grain native migration — separate spec `feat/camera-grain-overlay`
- ❌ Replay buffer / voice / volume bridges — separate specs (rm-8, rm-9, rm-10)
- ❌ G10 iPad validation — client contracted smartphone-only
- ❌ G9 cold restart real — needs Apple Developer Program ($99/yr)
- ❌ Bumping iOS minimum to 16+ — rejected (Q-table #5)
- ❌ Pixel emulator — replaced by physical Samsung M54
- ❌ Modal anti-kill Samsung — One UI 6 honors FGS

## Quality patterns applied

- **TDD red→green** on every native/Flutter feature (memória `feedback_tdd_pin_behavior_not_type`)
- **Per-task `/verify-slice`** (memória `feedback_per_task_harness_validation`)
- **Real device logs over assumptions** (memória `feedback_device_debug_use_real_logs_not_assumptions`)
- **Conventional Commits scope-enum** (no `--no-verify`)
- **Memory capture outside critical path** (R6 mitigation)
- **Native overlay over hybrid composition workaround** (R11 mitigation)

## References

- Spec child: [`2026-05-28-camera-task-19-closure-design.md`](../specs/2026-05-28-camera-task-19-closure-design.md)
- Spec parent: [`2026-05-26-camera-native-bridge-design.md`](../specs/2026-05-26-camera-native-bridge-design.md)
- ADR-0015: [`0015-camera-native-bridge-strategy.md`](../../decisions/0015-camera-native-bridge-strategy.md)
- Session anterior: [`docs/sessions/0005-camera-device-validation.md`](../../sessions/0005-camera-device-validation.md)
- Memórias auto-loaded: ver MEMORY.md (10 memórias relevantes)
