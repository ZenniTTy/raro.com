# Sprint 2 — S2.A: Recording real + Vault — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the REC button on the real camera screen (P05) record a real MP4 to an app-private vault, list it in the gallery, and play it back in preview — on iPhone 12 iOS, gate G1 tap→started <300ms.

**Architecture:** Add `startRecording`/`stopRecording` to the existing Pigeon `CameraHostApi`; implement a native `RecordingPipeline` (Swift, `AVCaptureMovieFileOutput`) attached to the already-running `AVCaptureSession`. On the Dart side, P05 stops being a mock: it mounts the real `CameraPreviewWidget` (UiKitView) and drives the real session lifecycle via the existing `CameraController` + `CameraRepository` port, and the REC button calls real start/stop. A new `VaultService` (Dart, injected `Directory` for testability) copies the produced MP4 into `<documents>/vault/` and lists it; the gallery's `videoListProvider` reads the vault. Decisions recorded in a new ADR-0018 (recording crosses ADR-0015's explicit "sem gravação" boundary).

**Tech Stack:** AVFoundation `AVCaptureMovieFileOutput` (Swift, iOS 15+), Pigeon 26.3.2, `path_provider ^2.1.5`, Riverpod 3 codegen, freezed, mocktail, XCTest.

---

## Decisions locked before coding (Think-Before-Coding outcome)

These were resolved with the user + adr-guardian + Apple-docs research. Do NOT re-litigate during execution.

1. **P05 gets the real preview + session** (user choice). `_Viewport` mounts `CameraPreviewWidget`; the screen drives `CameraController.start/stop`. Recording records the live session.
2. **`AVCaptureMovieFileOutput`, not `AVAssetWriter`** for Task A. Research ([Apple availableVideoCodecTypes](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput/availablevideocodectypes), [objc.io Capturing Video](https://www.objc.io/issues/23-video/capturing-video/)): MovieFileOutput is the minimal-config, lowest-latency path and supports HEVC + H.264 via `setOutputSettings([AVVideoCodecKey: ...], for: connection)`. `AVAssetWriter` is only needed when you must access `CMSampleBuffer`s in real time — that is the **replay buffer** (Task B / S2.B), a *separate* output decided in ADR-0003 refresh. Karpathy Simplicity First: do not pre-build AssetWriter here.
3. **Codec default = HEVC (h265)** with H.264 fallback when `availableVideoCodecTypes` lacks HEVC. New `Codec` enum in `raro_shared`. (HEVC = smaller files, iPhone 12 encodes it in hardware.)
4. **ADR-0018 first** (adr-guardian verdict, verified: ADR-0015 line 21 item 7 = "Sem gravação nesta ADR — boundary explícito"). Recording crosses that boundary → new ADR required before touching the Pigeon contract.
5. **Device validation is the user's step.** This plan stops at "ready for device": analyze 0 + `flutter test` green + Swift XCTest green + iOS compiles. The user runs the iPhone 12 smoke + measures G1. The Blueprint §11 / §10 DONE mark waits for the user's device OK.

## Plan-vs-reality corrections (the plan MD in sprint-2 was written 29/mai, stale)

- `recording_state_provider.dart` **does not exist**. Recording UI state lives in `camera_shell_provider.dart` (`CameraShell` notifier, `CameraShellState`). We will introduce a real recording state but wire it through the existing screen, not invent the plan's filename.
- `VideoEntity` has **no `path`/`thumbnailPath`/`length`**. Its fields are `id, name, Duration duration, DateTime recordedAt, bool isReplay, int thumbnailHue`. We add an **optional `String? filePath`** (null = mock/no file) rather than reshaping it.
- `RecordingMetadata`, `RecordingOptions`, `Codec`, `RecordingSettings` (in shared) **do not exist** — we create what we need, reusing `Resolution`/`Fps`.
- Pigeon script is `bun run --filter '@raro/mobile' pigeon` (regenerates all 4 bridges). Swift output is `ios/Runner/Native/Generated/CameraApi.g.swift` (NOT `Pigeon/`).
- Analytics: `AnalyticsEvents.recordingStarted/recordingEnded/recordingFailed` + `RecordingStartedPayload` already exist in `raro_shared` (payload uses `Lens`, `ControlMode trigger`, `BufferDuration`). We emit on real start/stop.

## File structure (what each new/changed file owns)

| File | Responsibility | New/Modify |
|---|---|---|
| `docs/decisions/0018-recording-pipeline-mp4.md` | ADR: recording output API + codec + contract boundary | Create |
| `packages/shared/lib/src/enums/codec.dart` | `Codec` enum (h264, h265) + labels | Create |
| `packages/shared/lib/raro_shared.dart` | export codec | Modify |
| `apps/mobile/pigeons/camera_api.dart` | add `startRecording(RecordingOptions)`, `stopRecording()`, `RecordingOptions` class, `onRecordingFinished`/`onRecordingFailed` FlutterApi | Modify |
| `apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart` | regenerated | Regenerate |
| `apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift` | regenerated | Regenerate |
| `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift` | attach `AVCaptureMovieFileOutput`, start/stop, codec selection, file URL, delegate callbacks | Create |
| `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift` | own a `RecordingPipeline`, expose `startRecording/stopRecording`, attach output at session start | Modify |
| `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift` | wire Pigeon `startRecording/stopRecording` → manager + FlutterApi callbacks | Modify |
| `apps/mobile/ios/RunnerTests/CameraManagerRecordingTests.swift` | XCTest: start→stop→MP4 exists >1KB | Create |
| `apps/mobile/lib/features/camera/data/camera_repository.dart` | add `startRecording`/`stopRecording` to port | Modify |
| `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart` | delegate new methods | Modify |
| `apps/mobile/lib/features/camera/data/vault_service.dart` | save(File, metadata)→VideoEntity, listAll(), injected `Directory` | Create |
| `apps/mobile/lib/features/camera/data/vault_service_provider.dart` | `@Riverpod(keepAlive)` resolving documents dir | Create |
| `apps/mobile/lib/features/camera/domain/recording_metadata.dart` | `RecordingMetadata` value type (id, name, duration, recordedAt, isReplay, thumbnailHue) | Create |
| `apps/mobile/lib/features/gallery/domain/video_entity.dart` | add `String? filePath` (default null) | Modify |
| `apps/mobile/lib/features/gallery/application/video_list_provider.dart` | read vault, fall back to mocks if empty | Modify |
| `apps/mobile/lib/features/camera/application/recording_controller.dart` | real REC start/stop → bridge (returns sessionId); `@riverpod` wrapper | Create |
| `apps/mobile/lib/features/camera/application/camera_flutter_api_provider.dart` | SOLE `CameraFlutterApi.setUp` registration (keepAlive); `recordingEvents` stream; save-to-vault listener → invalidate gallery + analytics | Create |
| `apps/mobile/lib/features/camera/presentation/camera_screen.dart` | mount real preview; drive session + recording via controllers; real elapsed timer | Modify |
| Tests under `apps/mobile/test/features/camera/...` | vault, recording_controller, repo delegation | Create |

---

## Task 0: ADR-0018 (gate — must merge intent before contract edit)

**Files:**
- Create: `docs/decisions/0018-recording-pipeline-mp4.md`

- [ ] **Step 1: Read the ADR template and ADR-0015**

Run: `cat docs/decisions/0000-template.md` and `cat docs/decisions/0015-camera-native-bridge-strategy.md`
Expected: template structure; confirm 0015 item 7 "Sem gravação".

- [ ] **Step 2: Write ADR-0018**

Create `docs/decisions/0018-recording-pipeline-mp4.md` following the template. Required content:
- **Status:** Accepted (2026-06-03)
- **Supersedes:** ADR-0015 item 7 ("Sem gravação") — recording is now in scope.
- **Context:** Sprint 2 G1 needs real MP4 recording on P05. Pigeon contract must gain start/stop. Session uses `sessionPreset = .inputPriority` (iPhone 12 dual-wide zoom mapping, ADR-0015 addendum).
- **Decision:**
  1. Output API = `AVCaptureMovieFileOutput` (file-based, minimal config, HEVC+H264). `AVAssetWriter` reserved for replay buffer (ADR-0003 refresh, Task B).
  2. Codec default HEVC (`AVVideoCodecType.hevc`), fallback H.264 when `availableVideoCodecTypes` lacks HEVC. Container `.mov`/`.mp4` via MovieFileOutput (`.mov` is what MovieFileOutput emits; we keep `.mp4` extension only if container is set — DECISION: keep MovieFileOutput's native `.mov` written to `<id>.mov`; gallery/preview/`video_player` handle `.mov` fine. Document this honestly.)
  3. Contract: `startRecording(RecordingOptions)→String sessionId`, `stopRecording()→void` (path delivered async via `onRecordingFinished(String path)` because MovieFileOutput finalizes the file in its delegate, not synchronously).
  4. New `Codec` enum in `raro_shared`.
- **Consequences:** MovieFileOutput cannot vend sample buffers → replay buffer (Task B) needs a *second* output (`AVCaptureVideoDataOutput`+`AVAssetWriter`); validate both can coexist on one `.inputPriority` session in Task B. Note this risk explicitly.
- **References:** ADR-0015, ADR-0013, ADR-0003; Apple availableVideoCodecTypes; sprint-2 plan Task A.

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0018-recording-pipeline-mp4.md
git commit -m "docs(bridge): adr-0018 recording pipeline mp4 avcapturemoviefileoutput"
```

> **Contract correction vs sprint-2 MD:** the MD's `stopRecording()` returns the path synchronously. That is wrong for MovieFileOutput (file finalizes in the delegate `didFinishRecordingTo` callback). We deliver the path via `onRecordingFinished` FlutterApi. This is the single most important design correction; it is recorded in the ADR.

---

## Task 1: Codec enum in raro_shared

**Files:**
- Create: `packages/shared/lib/src/enums/codec.dart`
- Modify: `packages/shared/lib/raro_shared.dart`
- Test: `packages/shared/test/enums/codec_test.dart`

- [ ] **Step 1: Write the failing test**

Create `packages/shared/test/enums/codec_test.dart`:

```dart
import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  test('Codec has h264 and h265 with stable labels', () {
    expect(Codec.h264.label, 'h264');
    expect(Codec.h265.label, 'h265');
    expect(Codec.values, hasLength(2));
  });

  test('Codec.fromLabel round-trips', () {
    for (final c in Codec.values) {
      expect(Codec.fromLabel(c.label), c);
    }
  });
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `cd packages/shared && dart test test/enums/codec_test.dart`
Expected: FAIL — `Codec` undefined.

- [ ] **Step 3: Implement the enum**

Create `packages/shared/lib/src/enums/codec.dart`:

```dart
enum Codec {
  h264('h264'),
  h265('h265');

  const Codec(this.label);

  final String label;

  static Codec fromLabel(String label) =>
      Codec.values.firstWhere((c) => c.label == label, orElse: () => Codec.h265);
}
```

Add to `packages/shared/lib/raro_shared.dart` (alongside the other enum exports):

```dart
export 'src/enums/codec.dart';
```

- [ ] **Step 4: Run test, verify it passes**

Run: `cd packages/shared && dart test test/enums/codec_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/shared/lib/src/enums/codec.dart packages/shared/lib/raro_shared.dart packages/shared/test/enums/codec_test.dart
git commit -m "feat(bridge): add codec enum (h264/h265) to raro_shared"
```

---

## Task 2: Pigeon contract — startRecording/stopRecording

**Files:**
- Modify: `apps/mobile/pigeons/camera_api.dart`
- Regenerate: `apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart`, `apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift`, `android/.../camera/CameraApi.g.kt`

**DONE criteria:** Pigeon regenerates with no errors; `flutter analyze` 0 issues; the generated Swift compiles in Task 4.

- [ ] **Step 1: Add to `camera_api.dart`** (inside the existing `@HostApi() CameraHostApi`, after `focusAt`):

```dart
  /// Starts recording on the running session. Returns a session id.
  String startRecording(RecordingOptions options);

  /// Stops recording. The saved file path arrives via
  /// [CameraFlutterApi.onRecordingFinished] (MovieFileOutput finalizes async).
  void stopRecording();
```

Add to the `@FlutterApi() CameraFlutterApi` (after `onError`):

```dart
  void onRecordingFinished(String path, int durationMs);
  void onRecordingFailed(CameraErrorCode code, String? message);
```

Add a new data class (Pigeon does not import raro_shared, so codec is a plain String):

```dart
class RecordingOptions {
  RecordingOptions({
    required this.resolution,
    required this.fps,
    required this.codec,
  });

  Resolution resolution;
  Fps fps;
  String codec; // Codec.label: "h264" | "h265"
}
```

- [ ] **Step 2: Regenerate**

Run: `bun run --filter '@raro/mobile' pigeon`
Expected: regenerates 4 bridges; no errors. (If "No packages matched the filter" → arg order wrong; this form is correct per memory `raro-pattern-bun-filter-arg-order`.)

- [ ] **Step 3: Verify generation**

Run: `grep -n "startRecording\|stopRecording\|onRecordingFinished\|RecordingOptions" apps/mobile/lib/core/native_bridges/generated/camera_api.g.dart apps/mobile/ios/Runner/Native/Generated/CameraApi.g.swift`
Expected: symbols present in both Dart and Swift.

- [ ] **Step 4: Analyze**

Run: `bun run --filter '@raro/mobile' analyze`
Expected: 0 issues (generated Dart compiles; Swift host impl is added in Task 4 — analyze is Dart-only, so this passes now).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/pigeons/camera_api.dart apps/mobile/lib/core/native_bridges/generated/ apps/mobile/ios/Runner/Native/Generated/ apps/mobile/android/app/src/main/kotlin/com/rarocamera/raro_mobile/generated/
git commit -m "feat(bridge): pigeon start/stop recording + recordingoptions + onRecordingFinished"
```

> Note: regenerating touches the Kotlin `.g.kt` files too (the `pigeon` script does all 4). That is expected and harmless — Android impl is Sprint 3. Stage them so the working tree stays clean.

---

## Task 3: RecordingPipeline.swift (TDD red-before-green)

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift`
- Create: `apps/mobile/ios/RunnerTests/CameraManagerRecordingTests.swift`
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraManager.swift`

**DONE criteria:** XCTest `CameraManagerRecordingTests` proves a `RecordingPipeline` reports `isRecording` correctly and produces a non-nil output URL with the right extension/codec selection logic that is unit-testable WITHOUT a live camera (the pure parts). Live capture is validated on device by the user.

> **TDD honesty:** a Simulator/CI XCTest has no camera, so we cannot assert "MP4 > 1KB" deterministically in unit tests (that is the device smoke). We TDD the **testable surface**: codec selection given an `availableVideoCodecTypes` set, the output URL/extension, and the recording-state flag. The plan's "MP4 exists > 1KB" assertion is the device smoke (Step 7), not the XCTest.

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/ios/RunnerTests/CameraManagerRecordingTests.swift`:

```swift
import AVFoundation
import XCTest
@testable import Runner

final class CameraManagerRecordingTests: XCTestCase {
  func testCodecSelectionPrefersHevcWhenAvailable() {
    let chosen = RecordingPipeline.selectCodec(
      requested: "h265",
      available: [.hevc, .h264]
    )
    XCTAssertEqual(chosen, .hevc)
  }

  func testCodecSelectionFallsBackToH264WhenHevcMissing() {
    let chosen = RecordingPipeline.selectCodec(
      requested: "h265",
      available: [.h264]
    )
    XCTAssertEqual(chosen, .h264)
  }

  func testCodecSelectionHonorsExplicitH264() {
    let chosen = RecordingPipeline.selectCodec(
      requested: "h264",
      available: [.hevc, .h264]
    )
    XCTAssertEqual(chosen, .h264)
  }

  func testOutputUrlUsesMovExtensionInVaultDir() {
    let url = RecordingPipeline.makeOutputURL(sessionId: "abc123")
    XCTAssertEqual(url.pathExtension, "mov")
    XCTAssertTrue(url.lastPathComponent.contains("abc123"))
  }

  func testNewPipelineIsNotRecording() {
    let pipeline = RecordingPipeline()
    XCTAssertFalse(pipeline.isRecording)
  }
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: FAIL — `RecordingPipeline` undefined / symbols missing.

- [ ] **Step 3: Implement `RecordingPipeline.swift`**

Create `apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift`:

```swift
@preconcurrency import AVFoundation
import Foundation
import os.log

private let recordingLog = OSLog(subsystem: "com.rarocamera", category: "recording")

enum RecordingPipelineError: Error {
  case notAttached
  case alreadyRecording
  case notRecording
}

final class RecordingPipeline: NSObject {
  private var movieOutput: AVCaptureMovieFileOutput?
  private var startedAt: CFTimeInterval = 0
  private var currentSessionId: String?

  var onFinished: ((URL, Int) -> Void)?
  var onFailed: ((String) -> Void)?

  var isRecording: Bool { movieOutput?.isRecording ?? false }

  static func selectCodec(
    requested: String,
    available: [AVVideoCodecType]
  ) -> AVVideoCodecType {
    if requested == "h264" {
      return available.contains(.h264) ? .h264 : (available.first ?? .h264)
    }
    if available.contains(.hevc) { return .hevc }
    if available.contains(.h264) { return .h264 }
    return available.first ?? .hevc
  }

  static func makeOutputURL(sessionId: String) -> URL {
    let dir = FileManager.default.temporaryDirectory
    return dir.appendingPathComponent("raro_\(sessionId).mov")
  }

  func attach(to session: AVCaptureSession) throws {
    let output = AVCaptureMovieFileOutput()
    guard session.canAddOutput(output) else {
      throw RecordingPipelineError.notAttached
    }
    session.addOutput(output)
    movieOutput = output
    os_log("recording output attached", log: recordingLog, type: .info)
  }

  func start(sessionId: String, requestedCodec: String) throws {
    guard let output = movieOutput else { throw RecordingPipelineError.notAttached }
    guard !output.isRecording else { throw RecordingPipelineError.alreadyRecording }
    if let connection = output.connection(with: .video) {
      let codec = Self.selectCodec(
        requested: requestedCodec,
        available: output.availableVideoCodecTypes
      )
      output.setOutputSettings([AVVideoCodecKey: codec], for: connection)
      os_log("recording codec=%{public}@", log: recordingLog, type: .info, "\(codec.rawValue)")
    }
    let url = Self.makeOutputURL(sessionId: sessionId)
    try? FileManager.default.removeItem(at: url)
    currentSessionId = sessionId
    startedAt = CACurrentMediaTime()
    output.startRecording(to: url, recordingDelegate: self)
    os_log("recording started id=%{public}@", log: recordingLog, type: .info, sessionId)
  }

  func stop() throws {
    guard let output = movieOutput, output.isRecording else {
      throw RecordingPipelineError.notRecording
    }
    output.stopRecording()
    os_log("recording stop requested", log: recordingLog, type: .info)
  }
}

extension RecordingPipeline: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    let durationMs = Int((CACurrentMediaTime() - startedAt) * 1000)
    if let error = error {
      os_log("recording failed: %{public}@", log: recordingLog, type: .error, error.localizedDescription)
      onFailed?(error.localizedDescription)
      return
    }
    os_log(
      "recording finished path=%{public}@ durationMs=%d",
      log: recordingLog, type: .info, outputFileURL.path, durationMs
    )
    onFinished?(outputFileURL, durationMs)
  }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS (5 tests).

- [ ] **Step 5: Integrate in `CameraManager.swift`**

Add a `private let recordingPipeline = RecordingPipeline()` stored property. In `startSession`, after `session.commitConfiguration()` and assigning `self.session`, attach the pipeline:

```swift
    try? recordingPipeline.attach(to: session)
```

Add manager methods:

```swift
  func startRecording(sessionId: String, codec: String) throws {
    guard session != nil else { throw CameraNativeError.notRunning }
    try recordingPipeline.start(sessionId: sessionId, requestedCodec: codec)
  }

  func stopRecording() throws {
    try recordingPipeline.stop()
  }

  var onRecordingFinished: ((URL, Int) -> Void)? {
    get { recordingPipeline.onFinished }
    set { recordingPipeline.onFinished = newValue }
  }

  var onRecordingFailed: ((String) -> Void)? {
    get { recordingPipeline.onFailed }
    set { recordingPipeline.onFailed = newValue }
  }
```

- [ ] **Step 6: Re-run XCTest (regression)**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS (5 tests; focus tests still green).

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/RecordingPipeline.swift apps/mobile/ios/RunnerTests/CameraManagerRecordingTests.swift apps/mobile/ios/Runner/Native/Camera/CameraManager.swift
git commit -m "feat(camera): recording pipeline avcapturemoviefileoutput + xctests"
```

---

## Task 4: Wire Pigeon host (Swift) → CameraManager

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift`

**DONE criteria:** Swift compiles for Simulator; `startRecording` returns a session id; `onRecordingFinished`/`onRecordingFailed` forward to `CameraFlutterApi`.

- [ ] **Step 1: Wire callbacks in `init(messenger:)`** (after the existing `manager.onFocusResult = ...` block):

```swift
    manager.onRecordingFinished = { [weak self] url, durationMs in
      DispatchQueue.main.async {
        self?.flutterApi.onRecordingFinished(path: url.path, durationMs: Int64(durationMs)) { _ in }
      }
    }
    manager.onRecordingFailed = { [weak self] message in
      DispatchQueue.main.async {
        self?.flutterApi.onRecordingFailed(code: .sessionFailed, message: message) { _ in }
      }
    }
```

- [ ] **Step 2: Implement the two new HostApi methods** (the protocol now requires them; add after `focusAt`):

```swift
  func startRecording(
    options: RecordingOptions,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    let sessionId = UUID().uuidString
    do {
      try manager.startRecording(sessionId: sessionId, codec: options.codec)
      completion(.success(sessionId))
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .sessionFailed, message: error.localizedDescription)))
    }
  }

  func stopRecording(completion: @escaping (Result<Void, Error>) -> Void) {
    do {
      try manager.stopRecording()
      completion(.success(()))
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .sessionFailed, message: error.localizedDescription)))
    }
  }
```

- [ ] **Step 2b: Confirm `UUID()` is allowed.** It is — only Dart-side `Date.now()`/`Math.random()` are workflow-script restricted; native Swift has no such limit.

- [ ] **Step 3: Compile for Simulator**

Run: `cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always flutter build ios --simulator --no-codesign`
Expected: BUILD succeeds OR fails only with the pre-existing `SUPPORTED_PLATFORMS = iphoneos` condition (CLAUDE.md §13). If it fails with a Swift type error in CameraHostApiImpl, fix and re-run. Watch for the deceptive background exit-0 (memory): confirm `✓ Built` text.

- [ ] **Step 4: Re-run XCTest**

Run: `bun run --filter '@raro/mobile' test:ios`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/ios/Runner/Native/Camera/CameraHostApiImpl.swift
git commit -m "feat(camera): wire pigeon start/stop recording host impl + flutter callbacks"
```

---

## Task 5: RecordingMetadata domain type

**Files:**
- Create: `apps/mobile/lib/features/camera/domain/recording_metadata.dart`
- Test: `apps/mobile/test/features/camera/domain/recording_metadata_test.dart`

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/features/camera/domain/recording_metadata_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

void main() {
  test('RecordingMetadata holds all fields', () {
    final at = DateTime(2026, 6, 3, 14, 30);
    const id = 'abc';
    final m = RecordingMetadata(
      id: id,
      name: 'Vídeo 14:30',
      duration: const Duration(seconds: 12),
      recordedAt: at,
      isReplay: false,
      thumbnailHue: 200,
    );
    expect(m.id, id);
    expect(m.duration, const Duration(seconds: 12));
    expect(m.isReplay, isFalse);
    expect(m.thumbnailHue, 200);
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `bun run --filter '@raro/mobile' test test/features/camera/domain/recording_metadata_test.dart`
Expected: FAIL — undefined.

- [ ] **Step 3: Implement**

Create `apps/mobile/lib/features/camera/domain/recording_metadata.dart`:

```dart
class RecordingMetadata {
  const RecordingMetadata({
    required this.id,
    required this.name,
    required this.duration,
    required this.recordedAt,
    required this.isReplay,
    required this.thumbnailHue,
  });

  final String id;
  final String name;
  final Duration duration;
  final DateTime recordedAt;
  final bool isReplay;
  final int thumbnailHue;
}
```

- [ ] **Step 4: Run, verify pass**

Run: `bun run --filter '@raro/mobile' test test/features/camera/domain/recording_metadata_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/camera/domain/recording_metadata.dart apps/mobile/test/features/camera/domain/recording_metadata_test.dart
git commit -m "feat(camera): recording metadata value type"
```

---

## Task 6: VideoEntity gains optional filePath

**Files:**
- Modify: `apps/mobile/lib/features/gallery/domain/video_entity.dart`
- Regenerate: `video_entity.freezed.dart`
- Test: `apps/mobile/test/features/gallery/video_entity_test.dart` (extend)

- [ ] **Step 1: Add the failing assertion** to the existing `video_entity_test.dart` (append a test):

```dart
  test('VideoEntity filePath defaults to null and round-trips', () {
    final v = VideoEntity(
      id: '1', name: 'x', duration: Duration.zero,
      recordedAt: DateTime(2026), isReplay: false, thumbnailHue: 0,
    );
    expect(v.filePath, isNull);
    expect(v.copyWith(filePath: '/vault/1.mov').filePath, '/vault/1.mov');
  });
```

- [ ] **Step 2: Run, verify fail**

Run: `bun run --filter '@raro/mobile' test test/features/gallery/video_entity_test.dart`
Expected: FAIL — `filePath` undefined.

- [ ] **Step 3: Add the field** to `video_entity.dart` factory (after `thumbnailHue`):

```dart
    String? filePath,
```

- [ ] **Step 4: Regenerate freezed**

Run: `bun run --filter '@raro/mobile' codegen`
Expected: `video_entity.freezed.dart` regenerated with `filePath`.

- [ ] **Step 5: Run, verify pass**

Run: `bun run --filter '@raro/mobile' test test/features/gallery/video_entity_test.dart`
Expected: PASS. Then full gallery suite green:
Run: `bun run --filter '@raro/mobile' test test/features/gallery/`
Expected: PASS (mocks still valid — filePath null is fine).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/gallery/domain/video_entity.dart apps/mobile/lib/features/gallery/domain/video_entity.freezed.dart apps/mobile/test/features/gallery/video_entity_test.dart
git commit -m "feat(gallery): video_entity optional filePath for real vault videos"
```

---

## Task 7: VaultService (TDD, injected Directory)

**Files:**
- Create: `apps/mobile/lib/features/camera/data/vault_service.dart`
- Create: `apps/mobile/lib/features/camera/data/vault_service_provider.dart`
- Test: `apps/mobile/test/features/camera/data/vault_service_test.dart`

**DONE criteria:** save copies a source file into `<dir>/vault/<id>.mov`, returns a `VideoEntity` with `filePath` set; `listAll` returns saved files sorted newest-first; `delete` removes. All testable with a temp `Directory` (no platform channel) per memory `raro-pattern-shared-preferences-async-untestable-use-port`.

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/features/camera/data/vault_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';

void main() {
  late Directory tempRoot;
  late File source;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vault_test_');
    source = File('${tempRoot.path}/src.mov')..writeAsBytesSync(List.filled(2048, 7));
  });

  tearDown(() async {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  RecordingMetadata meta(String id, {DateTime? at, bool replay = false}) =>
      RecordingMetadata(
        id: id, name: 'Vídeo $id',
        duration: const Duration(seconds: 5),
        recordedAt: at ?? DateTime(2026, 6, 3),
        isReplay: replay, thumbnailHue: 100,
      );

  test('save copies file into vault and returns entity with filePath', () async {
    final service = VaultService(documentsDir: tempRoot);
    final entity = await service.save(source, metadata: meta('a1'));
    expect(entity.id, 'a1');
    expect(entity.filePath, endsWith('vault/a1.mov'));
    expect(File(entity.filePath!).existsSync(), isTrue);
    expect(File(entity.filePath!).lengthSync(), 2048);
  });

  test('listAll returns saved videos newest-first', () async {
    final service = VaultService(documentsDir: tempRoot);
    await service.save(source, metadata: meta('old', at: DateTime(2026, 1, 1)));
    await service.save(source, metadata: meta('new', at: DateTime(2026, 6, 1)));
    final all = await service.listAll();
    expect(all.map((v) => v.id).toList(), ['new', 'old']);
  });

  test('listAll on empty vault returns []', () async {
    final service = VaultService(documentsDir: tempRoot);
    expect(await service.listAll(), isEmpty);
  });

  test('delete removes the file and it disappears from listAll', () async {
    final service = VaultService(documentsDir: tempRoot);
    final e = await service.save(source, metadata: meta('d1'));
    await service.delete(e.id);
    expect(File(e.filePath!).existsSync(), isFalse);
    expect(await service.listAll(), isEmpty);
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `bun run --filter '@raro/mobile' test test/features/camera/data/vault_service_test.dart`
Expected: FAIL — undefined.

- [ ] **Step 3: Implement `vault_service.dart`**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class VaultService {
  VaultService({required this.documentsDir});

  final Directory documentsDir;

  Directory get _vaultDir => Directory('${documentsDir.path}/vault');
  File _metaFile(String id) => File('${_vaultDir.path}/$id.json');
  File _videoFile(String id) => File('${_vaultDir.path}/$id.mov');

  Future<VideoEntity> save(File source, {required RecordingMetadata metadata}) async {
    await _vaultDir.create(recursive: true);
    final dest = _videoFile(metadata.id);
    await source.copy(dest.path);
    await _metaFile(metadata.id).writeAsString(jsonEncode(_encode(metadata)));
    return _toEntity(metadata, dest.path);
  }

  Future<List<VideoEntity>> listAll() async {
    if (!_vaultDir.existsSync()) return [];
    final metas = _vaultDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => _decode(jsonDecode(f.readAsStringSync()) as Map<String, Object?>))
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return metas.map((m) => _toEntity(m, _videoFile(m.id).path)).toList();
  }

  Future<void> delete(String id) async {
    final video = _videoFile(id);
    final meta = _metaFile(id);
    if (video.existsSync()) await video.delete();
    if (meta.existsSync()) await meta.delete();
  }

  VideoEntity _toEntity(RecordingMetadata m, String path) => VideoEntity(
        id: m.id,
        name: m.name,
        duration: m.duration,
        recordedAt: m.recordedAt,
        isReplay: m.isReplay,
        thumbnailHue: m.thumbnailHue,
        filePath: path,
      );

  Map<String, Object?> _encode(RecordingMetadata m) => {
        'id': m.id,
        'name': m.name,
        'durationMs': m.duration.inMilliseconds,
        'recordedAt': m.recordedAt.toIso8601String(),
        'isReplay': m.isReplay,
        'thumbnailHue': m.thumbnailHue,
      };

  RecordingMetadata _decode(Map<String, Object?> j) => RecordingMetadata(
        id: j['id']! as String,
        name: j['name']! as String,
        duration: Duration(milliseconds: j['durationMs']! as int),
        recordedAt: DateTime.parse(j['recordedAt']! as String),
        isReplay: j['isReplay']! as bool,
        thumbnailHue: j['thumbnailHue']! as int,
      );
}
```

> Design note: we persist a sidecar `<id>.json` so `listAll` reconstructs metadata (name/duration/hue) without re-probing the video file. Simpler and deterministic than parsing MP4 atoms; YAGNI on a thumbnail package for now (gallery uses `thumbnailHue` gradient, no PNG — matches Sprint 1 design).

- [ ] **Step 4: Run, verify pass**

Run: `bun run --filter '@raro/mobile' test test/features/camera/data/vault_service_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Create `vault_service_provider.dart`**

```dart
import 'package:path_provider/path_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<VaultService> vaultService(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return VaultService(documentsDir: dir);
}
```

- [ ] **Step 6: Codegen + analyze**

Run: `bun run --filter '@raro/mobile' codegen && bun run --filter '@raro/mobile' analyze`
Expected: `vault_service_provider.g.dart` generated; 0 issues.

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/lib/features/camera/data/vault_service.dart apps/mobile/lib/features/camera/data/vault_service_provider.dart apps/mobile/lib/features/camera/data/vault_service_provider.g.dart apps/mobile/test/features/camera/data/vault_service_test.dart
git commit -m "feat(vault): vault_service save/list/delete + provider (injected dir)"
```

---

## Task 8: Repository port + delegation for recording

**Files:**
- Modify: `apps/mobile/lib/features/camera/data/camera_repository.dart`
- Modify: `apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart`
- Test: `apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart` (extend)

- [ ] **Step 1: Add failing delegation tests** (append to existing file, matching its style):

```dart
  test('startRecording forwards options + returns session id', () async {
    final api = _MockHostApi();
    when(() => api.startRecording(any())).thenAnswer((_) async => 'sess-1');
    final repo = PigeonCameraRepository(api);
    final id = await repo.startRecording(
      RecordingOptions(resolution: Resolution.fhd1080, fps: Fps.fps60, codec: 'h265'),
    );
    expect(id, 'sess-1');
    final captured = verify(() => api.startRecording(captureAny())).captured;
    final opts = captured.single as RecordingOptions;
    expect(opts.resolution, Resolution.fhd1080);
    expect(opts.fps, Fps.fps60);
    expect(opts.codec, 'h265');
  });

  test('stopRecording delegates to host api', () async {
    final api = _MockHostApi();
    when(api.stopRecording).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.stopRecording();
    verify(api.stopRecording).called(1);
  });
```

Also add to `setUpAll`:

```dart
    registerFallbackValue(
      RecordingOptions(resolution: Resolution.fhd1080, fps: Fps.fps30, codec: 'h265'),
    );
```

- [ ] **Step 2: Run, verify fail**

Run: `bun run --filter '@raro/mobile' test test/features/camera/data/pigeon_camera_repository_test.dart`
Expected: FAIL — `startRecording`/`stopRecording` not on port.

- [ ] **Step 3: Add to port** `camera_repository.dart` (after `focusAt`):

```dart
  Future<String> startRecording(RecordingOptions options);
  Future<void> stopRecording();
```

Add to `pigeon_camera_repository.dart`:

```dart
  @override
  Future<String> startRecording(RecordingOptions options) =>
      _api.startRecording(options);

  @override
  Future<void> stopRecording() => _api.stopRecording();
```

- [ ] **Step 4: Run, verify pass**

Run: `bun run --filter '@raro/mobile' test test/features/camera/data/pigeon_camera_repository_test.dart`
Expected: PASS (all, incl. the 2 new).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/camera/data/camera_repository.dart apps/mobile/lib/features/camera/data/pigeon_camera_repository.dart apps/mobile/test/features/camera/data/pigeon_camera_repository_test.dart
git commit -m "feat(camera): camera repository port + delegation for recording"
```

---

## Task 9: RecordingController (real start/stop → vault → gallery + analytics)

**Files:**
- Create: `apps/mobile/lib/features/camera/application/recording_controller.dart`
- Create: `apps/mobile/lib/features/camera/application/recording_controller.g.dart` (codegen)
- Test: `apps/mobile/test/features/camera/application/recording_controller_test.dart`

**DONE criteria:** `toggle()` when idle calls `repo.startRecording` with options derived from settings, sets state to recording with `startedAt`. The `onRecordingFinished` path saves to vault and invalidates `videoListProvider`. Analytics `recordingStarted` emitted with the correct payload (pin-behavior: field asserts + captured payload, per memory `feedback_tdd_pin_behavior_not_type`).

> **State design:** introduce a small freezed `RecordingState` (idle | active(sessionId, startedAt)) inside the controller file's domain import, OR reuse a bool + nullable. To keep it testable and explicit, use a sealed `RecordingPhase`. The controller subscribes to the bridge's `onRecordingFinished` via a callback registered by the repository. Because `CameraFlutterApi` callbacks are global (Pigeon `setUp`), we route them through a stream the controller listens to.

- [ ] **Step 1: Define the recording state file** `apps/mobile/lib/features/camera/domain/recording_phase.dart`:

```dart
sealed class RecordingPhase {
  const RecordingPhase();
}

class RecordingIdle extends RecordingPhase {
  const RecordingIdle();
}

class RecordingActive extends RecordingPhase {
  const RecordingActive({required this.sessionId, required this.startedAt});
  final String sessionId;
  final DateTime startedAt;
}
```

- [ ] **Step 2: Write the failing controller test**

Create `apps/mobile/test/features/camera/application/recording_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/recording_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';

class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RecordingOptions(resolution: Resolution.fhd1080, fps: Fps.fps30, codec: 'h265'),
    );
  });

  test('start: idle → active with sessionId, calls repo.startRecording', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-1');
    final controller = RecordingController(repo: repo);
    await controller.start(
      RecordingOptions(resolution: Resolution.fhd1080, fps: Fps.fps60, codec: 'h265'),
    );
    final phase = controller.phase;
    expect(phase, isA<RecordingActive>());
    expect((phase as RecordingActive).sessionId, 's-1');
    final opts = verify(() => repo.startRecording(captureAny())).captured.single as RecordingOptions;
    expect(opts.fps, Fps.fps60);
    expect(opts.codec, 'h265');
  });

  test('stop: active → calls repo.stopRecording, phase back to idle', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-2');
    when(repo.stopRecording).thenAnswer((_) async {});
    final controller = RecordingController(repo: repo);
    await controller.start(
      RecordingOptions(resolution: Resolution.fhd1080, fps: Fps.fps30, codec: 'h264'),
    );
    await controller.stop();
    verify(repo.stopRecording).called(1);
    expect(controller.phase, isA<RecordingIdle>());
  });
}
```

> This first cut tests `RecordingController` as a plain class (repo-injected) — the testable core. The Riverpod `@riverpod` wrapper + the FlutterApi-callback→vault wiring is added in Step 4–5 and validated on device (vault save needs a real file).

- [ ] **Step 3: Run, verify fail**

Run: `bun run --filter '@raro/mobile' test test/features/camera/application/recording_controller_test.dart`
Expected: FAIL — undefined.

- [ ] **Step 4: Implement the controller core**

Create `apps/mobile/lib/features/camera/application/recording_controller.dart`:

```dart
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';

class RecordingController {
  RecordingController({required this.repo});

  final CameraRepository repo;
  RecordingPhase _phase = const RecordingIdle();

  RecordingPhase get phase => _phase;

  Future<void> start(RecordingOptions options) async {
    if (_phase is RecordingActive) return;
    final sessionId = await repo.startRecording(options);
    _phase = RecordingActive(sessionId: sessionId, startedAt: DateTime.now());
  }

  Future<void> stop() async {
    if (_phase is! RecordingActive) return;
    await repo.stopRecording();
    _phase = const RecordingIdle();
  }
}
```

- [ ] **Step 5: Run, verify pass**

Run: `bun run --filter '@raro/mobile' test test/features/camera/application/recording_controller_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/camera/domain/recording_phase.dart apps/mobile/lib/features/camera/application/recording_controller.dart apps/mobile/test/features/camera/application/recording_controller_test.dart
git commit -m "feat(camera): recording controller core (start/stop via repo port)"
```

> **Riverpod + callback wiring deferred to Task 10** (it touches the screen and the global FlutterApi handler — best done where the session lifecycle lives, to keep this task's diff focused and the core unit-tested).

---

## Task 10: Wire P05 — real preview + session lifecycle + REC

**Files:**
- Modify: `apps/mobile/lib/features/camera/presentation/camera_screen.dart`
- Modify: `apps/mobile/lib/features/gallery/application/video_list_provider.dart`
- Test: `apps/mobile/test/features/camera/camera_screen_test.dart` (adjust existing — preview now mounts a PlatformView; tests run on Flutter test binding where PlatformView renders as empty, so assert structure not pixels)

**DONE criteria:** P05 mounts the real preview, starts the session on entry, REC calls real start/stop, the elapsed timer reflects real recording, gallery reads the vault. `flutter test` green. Device smoke validates G1.

> **This is the integration task. It will not be fully unit-verifiable** (PlatformView + native session + real file need a device). The Flutter-test-level goal is: widget tree builds without throwing, existing camera_screen tests adapted, gallery provider reads vault when present. Device is the user's gate.

- [ ] **Step 1: Adjust `videoListProvider`** to read vault, fall back to mocks when empty (so dev/empty vault still shows the gallery design):

```dart
@riverpod
Future<List<VideoEntity>> videoList(Ref ref) async {
  final vault = await ref.watch(vaultServiceProvider.future);
  final real = await vault.listAll();
  if (real.isNotEmpty) return real;
  return _mockVideos();
}
```

Move the existing 6-item list into a private `List<VideoEntity> _mockVideos()` function (keep it — it is the empty-state design and the test fixture).

Run: `bun run --filter '@raro/mobile' codegen` (provider deps changed).

- [ ] **Step 2: Mount real preview in `_Viewport`** — replace `ColoredBox(color: colors.bgDeep)` with the platform preview, keeping overlays:

```dart
        const Positioned.fill(child: CameraPreviewWidget(showOverlays: false)),
```

(Keep the existing rule-of-thirds + grain overlays already in `_Viewport`.) Add the import for `CameraPreviewWidget`.

- [ ] **Step 3: Drive the session lifecycle** in `_CameraScreenState`. **Consume `cameraControllerProvider` via `ref.watch` in `build`** (mirror the harness, line 143) so the autoDispose provider stays alive while P05 is mounted and its existing `ref.onDispose(() => _repo.stopSession())` fires on teardown — no manual `notifier.stop()` needed (and `ConsumerState.dispose()` cannot safely touch `ref` anyway). Start the session in `initState` via `addPostFrameCallback` (avoids provider-modify-during-build). Read settings from `settingsControllerProvider` (the real name — `settingsProvider` does NOT exist).

> **Adversarial-verify correction (check #5/#6):** the real settings provider is `settingsControllerProvider` (an `$AsyncNotifierProvider<SettingsController, RecordingSettings>` in `settings_controller.g.dart`), exposing `.future`. And P05 today consumes NEITHER `cameraControllerProvider` nor sessions — so we adopt the harness's `ref.watch` pattern, which makes `onDispose` the correct and sufficient stop mechanism. Do NOT add a manual `stop()` in `State.dispose()`.

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    final notifier = ref.read(cameraControllerProvider.notifier);
    final granted = await notifier.hasPermission();
    if (!granted || !mounted) return;
    final settings = await ref.read(settingsControllerProvider.future);
    await notifier.start(
      textureId: 0,
      settings: CameraSettings(
        lens: ref.read(cameraShellProvider).lens,
        resolution: settings.resolution,
        fps: settings.fps,
      ),
    );
  }
```

In `build`, add (near the existing `ref.watch(cameraShellProvider)`), so the controller has an active listener tied to the screen's lifetime:

```dart
    ref.watch(cameraControllerProvider);
```

This is what makes `CameraController`'s `ref.onDispose(() => _repo.stopSession())` (camera_controller.dart:31-33) fire when P05 is popped — verified: `cameraControllerProvider` is autoDispose; `cameraRepositoryProvider` is keepAlive but keepAlive does NOT propagate up to dependents, so the controller disposes on its own when P05 (its only listener) is gone.

- [ ] **Step 4: Real REC** — rewrite `_onRecTap` to call recording start/stop through a Riverpod-wrapped `RecordingController`. Add the `@riverpod` wrapper in `recording_controller.dart`:

```dart
@riverpod
RecordingController recordingController(Ref ref) =>
    RecordingController(repo: ref.watch(cameraRepositoryProvider));
```

Register the `CameraFlutterApi` recording callbacks **exactly once, in a dedicated keepAlive Riverpod provider** (NOT in `main.dart`/`app.dart`). Rationale (adversarial-verify #4): `CameraFlutterApi.setUp(api, ...)` is **static + global** (one `setMessageHandler` per channel, last-writer-wins), so a single keepAlive provider guarantees one registration for the app lifetime; it also gives the handler a `Ref` to bridge the side-effects (vault save + `ref.invalidate(videoListProvider)` + `recordingEnded` analytics) into Riverpod. The side-effects live in this ONE listener — never duplicated per screen-mount. Create `apps/mobile/lib/features/camera/application/camera_flutter_api_provider.dart`:

```dart
@Riverpod(keepAlive: true)
Raw<Stream<RecordingResult>> recordingEvents(Ref ref) {
  final controller = StreamController<RecordingResult>.broadcast();
  final handler = _RecordingFlutterApi(controller);
  CameraFlutterApi.setUp(handler);
  ref.onDispose(() {
    CameraFlutterApi.setUp(null);
    controller.close();
  });
  return controller.stream;
}

class _RecordingFlutterApi implements CameraFlutterApi {
  _RecordingFlutterApi(this._sink);
  final StreamController<RecordingResult> _sink;

  @override
  void onRecordingFinished(String path, int durationMs) =>
      _sink.add(RecordingResult.finished(path: path, durationMs: durationMs));

  @override
  void onRecordingFailed(CameraErrorCode code, String? message) =>
      _sink.add(RecordingResult.failed(code: code, message: message));

  // The other CameraFlutterApi callbacks (onSessionStarted/Stopped/onLensSwitched/
  // onFocusChanged/onError) are already handled by CameraHostApiImpl's own wiring on
  // the NATIVE side via direct manager callbacks; here we only need the recording ones,
  // but the Dart abstract requires all — provide no-op bodies for the rest, OR (cleaner)
  // keep ONE CameraFlutterApi handler app-wide that also forwards focus/lens/session.
  // DECISION: this provider owns the SOLE CameraFlutterApi registration. Implement every
  // method; forward focus/lens/session to their existing listeners if any consume them.
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
}
```

(`RecordingResult` is a tiny sealed type — define alongside, finished{path,durationMs} | failed{code,message}.) A second keepAlive provider listens to `recordingEvents` and performs the save: on `finished`, read `vaultServiceProvider`, build `RecordingMetadata` (id from the path stem, name `'Vídeo HH:MM'`, duration from `durationMs`, recordedAt now, isReplay false, a thumbnailHue), `vault.save(File(path), metadata: ...)`, then `ref.invalidate(videoListProvider)` and emit `recordingEnded` analytics. **This whole seam is the part the user verifies on device.**

> **Important contract note:** because this provider becomes the SOLE `CameraFlutterApi` handler, confirm nothing else calls `CameraFlutterApi.setUp` (verified today: zero existing Dart registrations). If a future screen needs focus/lens/session callbacks, route them through this same provider — never a second `setUp`.

In `_onRecTap`:

```dart
  Future<void> _onRecTap() async {
    final controller = ref.read(recordingControllerProvider);
    if (controller.phase is RecordingActive) {
      await controller.stop();
      _timer?.cancel(); _timer = null; _elapsed = Duration.zero;
    } else {
      final settings = await ref.read(settingsControllerProvider.future);
      await controller.start(RecordingOptions(
        resolution: settings.resolution,
        fps: settings.fps,
        codec: Codec.h265.label,
      ));
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1),
          (_) => setState(() => _elapsed += const Duration(seconds: 1)));
    }
    setState(() {});
  }
```

(Keep `cameraShellProvider` for lens/buffer UI state, but recording boolean now derives from `recordingController.phase`. Update the `_Viewport recording:` arg accordingly.)

- [ ] **Step 5: Adapt existing widget tests**

Run: `bun run --filter '@raro/mobile' test test/features/camera/camera_screen_test.dart`
Fix any test that assumed the mock `toggleRecording` bool. Where a test pumped the screen and toggled REC, it must now stub `cameraRepositoryProvider` with a mock (override in `ProviderScope`). Use the existing mock pattern from `pigeon_camera_repository_test.dart`.
Expected: PASS after adaptation.

- [ ] **Step 6: Full suite + analyze**

Run: `bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test`
Expected: 0 issues; all tests green (target ≥200, +new). If `flutter_tester` orphans hang the run, `pkill -f "flutter_tester --disable-vm-service"` (memory).

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/lib/features/camera/presentation/camera_screen.dart apps/mobile/lib/features/camera/application/recording_controller.dart apps/mobile/lib/features/camera/application/recording_controller.g.dart apps/mobile/lib/features/gallery/application/video_list_provider.dart apps/mobile/lib/features/gallery/application/video_list_provider.g.dart apps/mobile/test/
git commit -m "feat(camera): wire p05 real preview + session + rec->vault->gallery"
```

---

## Task 11: Ready-for-device verification (no device — user runs the smoke)

**Files:** none (verification only).

- [ ] **Step 1: Compile iOS for device (not run)**

Run: `cd apps/mobile && GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always flutter build ios --profile`
Expected: `✓ Built ...Runner.app`. If SPM `Couldn't check out revision` → compare the two `Package.resolved` (`.xcodeproj` vs `.xcworkspace`) per memory `raro-pattern-spm-package-resolved-divergent`. Confirm timestamp of the `.app` (deceptive background exit-0 memory).

- [ ] **Step 2: Final green gates**

Run: `bun run --filter '@raro/mobile' analyze && bun run --filter '@raro/mobile' test && bun run --filter '@raro/mobile' test:ios`
Expected: 0 issues; Flutter suite green; XCTest green.

- [ ] **Step 3: Hand off to user for device smoke (G1)**

Provide the user this checklist to run on the iPhone 12:
- Launch app → camera P05 shows **live preview** (not black).
- Tap REC → indicator turns recording; measure tap→started via Xcode Console filter `subsystem:com.rarocamera category:recording` → "recording started" should appear <300ms after tap (G1).
- Record ~3s → tap REC again → "recording finished path=..." logged.
- Open Gallery → the new video appears (real, not mock).
- Tap it → Preview plays the recorded `.mov`.
- Report Console latency line + pass/fail.

- [ ] **Step 4: After user confirms device pass**

Update Blueprint §11 Sprint 2 — mark "Recording real (MP4 → vault)" with device-validated note. Then run `/session-end` (session 0016) with next objective = S2.B (Replay buffer). Commit: `docs(sprint-2): mark recording real device-validated + session 0016`.

> Do NOT mark G1/Blueprint DONE before the user reports the device pass (decision #5).

---

## Self-review (run before execution)

- **Spec coverage:** Task A A1 (Pigeon) = Task 2; A2 (RecordingPipeline.swift) = Tasks 3–4; A3 (VaultService) = Tasks 5–7; A4 (wire REC→vault→gallery) = Tasks 9–10. ADR gate (adr-guardian) = Task 0. P05 preview decision = Task 10. G1 = Task 11. ✅
- **Placeholder scan:** every code step has full code; no "TBD"/"handle errors"/"similar to". ✅
- **Type consistency:** `RecordingOptions{resolution:Resolution, fps:Fps, codec:String}` used identically in Tasks 2/8/9/10. `Codec.label` ("h265") feeds the String codec. `VideoEntity.filePath` added in Task 6, consumed in Task 7. `RecordingPhase`/`RecordingActive.sessionId` consistent Tasks 9/10. `selectCodec`/`makeOutputURL` static names match Tasks 3 test+impl. ✅
- **Known risks surfaced:** (a) `stopRecording` async path via callback (not sync return) — corrected in ADR + Task 2; (b) MovieFileOutput emits `.mov` not `.mp4` — documented; (c) MovieFileOutput vs replay-buffer AssetWriter coexistence — flagged to Task B; (d) global FlutterApi callback wiring is the device-validated seam — flagged in Task 10.

---

## Em palavras simples

Este plano transforma a tela da câmera (que hoje é uma maquete: o botão REC só "finge" gravar) em câmera de verdade no iPhone. A ordem é: primeiro registro a decisão técnica num documento (ADR-0018), porque gravar vídeo foi deixado de fora de propósito antes — então preciso "abrir a porta" formalmente. Depois ensino o lado nativo (Swift) a gravar um arquivo de vídeo de verdade, crio um "cofre" no app onde o vídeo é guardado, e ligo o botão REC + a câmera ao vivo na tela. Cada passo tem teste antes do código (TDD), e eu paro no ponto "pronto pro celular" — você roda no seu iPhone 12 e confirma que grava, aparece na galeria e toca. Só depois disso marco como concluído.
