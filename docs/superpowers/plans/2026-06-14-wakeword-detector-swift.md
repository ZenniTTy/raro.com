# WakeWordDetector.swift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the native iOS wake-word detector that turns 16kHz mic audio into `WakeCommand.start`/`.stop` by running the 3-stage ONNX pipeline (mel → embedding → classifier) on-device, without touching the VoiceManager/camera/Dart layers yet.

**Architecture:** Three focused Swift units — `OnnxModelSession` (thin ORT wrapper, the only ONNX-aware piece), `WakeWordPipeline` (pure stateful machine: ring buffers + threshold/debounce, depends on protocols so it's testable without ONNX), and `WakeWordDetector` (façade wiring real sessions into the pipeline). The 4 `.onnx` models get inserted into `project.pbxproj` so `Bundle.main` finds them.

**Tech Stack:** Swift 6 (`@preconcurrency AVFoundation`), ONNX Runtime SPM 1.24.2 (`ORTEnv`/`ORTSessionOptions`/`ORTSession`/`ORTValue`, `runWithInputs:outputs:runOptions:error:`), CoreML Execution Provider (`appendCoreMLExecutionProviderWithOptions:`), XCTest (serial). Pigeon contract `voice_api` UNCHANGED.

---

## Pre-flight (run once before Task 1)

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
# iOS build needs the 2 SPM git overrides (CLAUDE.md §13) — prefix any flutter build/run/test:ios with them.
# Confirm clean tree on feat/camera-native-bridge:
git status --short
git log --oneline -1
```

Expected: clean tree, HEAD at the spec commit (`6bd54a3` or later).

---

## Task 0: Verify graph shapes + adr-guardian gate (no code yet)

**Files:**
- Read: `docs/superpowers/notes/raro-model-training.md` (I/O contract)
- Read: `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md`

- [ ] **Step 1: Re-extract real graph shapes (don't trust session 0026)**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
python3 -m venv /tmp/onnxcheck && /tmp/onnxcheck/bin/pip install -q onnx
/tmp/onnxcheck/bin/python - <<'PY'
import onnx
base = "apps/mobile/ios/Runner/Resources/"
for f in ["melspectrogram","embedding_model","raro_gravar","raro_parar"]:
    g = onnx.load(base+f+".onnx").graph
    def shp(v):
        return [d.dim_value if d.dim_value else (d.dim_param or '?') for d in v.type.tensor_type.shape.dim]
    print(f, "IN", [(i.name, shp(i)) for i in g.input], "OUT", [(o.name, shp(o)) for o in g.output])
PY
```

Expected (must match contract — if it diverges, STOP and fix the contract before coding):
- `melspectrogram` IN `[('input', [1,'?'])]` OUT `[('output', ['?',1,'?',32])]`
- `embedding_model` IN `[('input_1', ['?',76,32,1])]` OUT `[('conv2d_19', ['?',1,1,96])]`
- `raro_gravar`/`raro_parar` IN `[('embeddings', ['?',16,96])]` OUT `[('score', ['?',1])]`

- [ ] **Step 2: adr-guardian gate**

Dispatch `adr-guardian` with: "Integrar ONNX Runtime via SPM no Runner (já resolvido) + inserir 4 `.onnx` no `project.pbxproj` Copy Bundle Resources + registrar a lib no Blueprint §2 — está coberto pelo ADR-0023 (Accepted) ou exige addendum?". Attach `docs/decisions/0023-voice-engine-dedicated-not-sfspeechrecognizer.md`.

Expected: GO (ADR-0023 already authorizes ONNX Runtime in Runner). If addendum requested, write it before Task 4.

- [ ] **Step 3: No commit** (verification only).

---

## Task 1: `WakeWordPipeline` — protocols + ring buffers (pure, Simulator)

This is the pure state machine. It depends on protocols, never on ONNX, so it's fully testable without a device.

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift`
- Test: `apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift`

- [ ] **Step 1: Write the failing test (audio accumulation triggers mel at exactly 1280 samples)**

`apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift`:

```swift
import XCTest
@testable import Runner

private final class FakeMel: MelExtracting {
  var callCount = 0
  var lastInputCount = 0
  func extract(_ samples: [Float]) -> [[Float]] {
    callCount += 1
    lastInputCount = samples.count
    return [[Float](repeating: 0, count: 32)]
  }
}

private final class FakeEmbedding: Embedding {
  func embed(_ melWindow: [[Float]]) -> [Float] { [Float](repeating: 0, count: 96) }
}

private final class FakeClassifier: Classifying {
  var fixedScore: Float = 0
  func classify(_ embeddings: [[Float]]) -> Float { fixedScore }
}

final class WakeWordPipelineTests: XCTestCase {
  func testMelRunsOnlyAfter1280Samples() {
    let mel = FakeMel()
    let pipeline = WakeWordPipeline(
      mel: mel, embedding: FakeEmbedding(),
      gravar: FakeClassifier(), parar: FakeClassifier(),
      gravarThreshold: 0.34, pararThreshold: 0.23
    )
    pipeline.process([Float](repeating: 0.1, count: 1279))
    XCTAssertEqual(mel.callCount, 0, "1279 samples must NOT trigger mel")
    pipeline.process([Float](repeating: 0.1, count: 1))
    XCTAssertEqual(mel.callCount, 1, "1280th sample triggers mel")
    XCTAssertEqual(mel.lastInputCount, 1280)
  }
}
```

- [ ] **Step 2: Add the 3 test files to pbxproj (4 insertions) so the test actually runs**

Edit `apps/mobile/ios/Runner.xcodeproj/project.pbxproj`. Use next-free IDs after `…F5`. For `WakeWordPipelineTests.swift` use `…F6` (build file) / `…F7` (file ref):

1. **PBXBuildFile** (near other `*Tests.swift in Sources`):
   `CA00000000000000000000F6 /* WakeWordPipelineTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = CA00000000000000000000F7 /* WakeWordPipelineTests.swift */; };`
2. **PBXFileReference** (near other test refs):
   `CA00000000000000000000F7 /* WakeWordPipelineTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WakeWordPipelineTests.swift; sourceTree = "<group>"; };`
3. **PBXGroup** of RunnerTests: add `CA00000000000000000000F7 /* WakeWordPipelineTests.swift */,` next to `AudioSessionCoordinatorTests.swift`.
4. **Sources build phase** of RunnerTests target: add `CA00000000000000000000F6 /* WakeWordPipelineTests.swift in Sources */,`.

Reference: memory `raro-pattern-ios-xctest-pbxproj-4-insertions`.

- [ ] **Step 3: Run test to verify it fails (compile error — types not defined)**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "WakeWordPipeline|error:|Test suite" | head
```
Expected: FAIL — `cannot find 'WakeWordPipeline'` / `MelExtracting` etc.

- [ ] **Step 4: Write minimal `WakeWordPipeline.swift`**

`apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift`:

```swift
import Foundation

protocol MelExtracting {
  func extract(_ samples: [Float]) -> [[Float]]
}

protocol Embedding {
  func embed(_ melWindow: [[Float]]) -> [Float]
}

protocol Classifying {
  func classify(_ embeddings: [[Float]]) -> Float
}

final class WakeWordPipeline {
  private let mel: MelExtracting
  private let embedding: Embedding
  private let gravar: Classifying
  private let parar: Classifying
  private let gravarThreshold: Float
  private let pararThreshold: Float

  private static let audioStep = 1280
  private static let melWindow = 76
  private static let melStep = 8
  private static let embeddingCount = 16

  private var audioBuffer: [Float] = []
  private var melBuffer: [[Float]] = []
  private var embeddingBuffer: [[Float]] = []

  init(mel: MelExtracting, embedding: Embedding,
       gravar: Classifying, parar: Classifying,
       gravarThreshold: Float, pararThreshold: Float) {
    self.mel = mel
    self.embedding = embedding
    self.gravar = gravar
    self.parar = parar
    self.gravarThreshold = gravarThreshold
    self.pararThreshold = pararThreshold
  }

  func process(_ samples: [Float]) {
    audioBuffer.append(contentsOf: samples)
    while audioBuffer.count >= Self.audioStep {
      let chunk = Array(audioBuffer.prefix(Self.audioStep))
      audioBuffer.removeFirst(Self.audioStep)
      let frames = mel.extract(chunk)
      melBuffer.append(contentsOf: frames)
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "WakeWordPipelineTests|Test suite|executed|failed" | head
```
Expected: `Test Suite 'WakeWordPipelineTests' started` + `testMelRunsOnlyAfter1280Samples` passed.

- [ ] **Step 6: Commit**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(voice): wakeword pipeline mel trigger at 1280 samples"
bun run --filter '@raro/mobile' test
```
Run the full Flutter suite after the commit (no batching — CLAUDE.md §6). Expected: green.

---

## Task 2: `WakeWordPipeline` — sliding mel window → embeddings

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift`
- Test: `apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift`

- [ ] **Step 1: Write the failing test (embedding runs once a 76-frame window exists, sliding by 8)**

Append to `WakeWordPipelineTests.swift`:

```swift
extension WakeWordPipelineTests {
  func testEmbeddingRunsWhenMelWindowFull() {
    let mel = FakeMel()
    // FakeMel returns 1 frame per 1280 samples; feed 76*1280 to fill one window.
    let embedding = CountingEmbedding()
    let pipeline = WakeWordPipeline(
      mel: mel, embedding: embedding,
      gravar: FakeClassifier(), parar: FakeClassifier(),
      gravarThreshold: 0.34, pararThreshold: 0.23
    )
    pipeline.process([Float](repeating: 0.1, count: 1280 * 75))
    XCTAssertEqual(embedding.callCount, 0, "75 frames < 76 window: no embedding yet")
    pipeline.process([Float](repeating: 0.1, count: 1280))
    XCTAssertEqual(embedding.callCount, 1, "76th frame fills the window")
  }
}

private final class CountingEmbedding: Embedding {
  var callCount = 0
  func embed(_ melWindow: [[Float]]) -> [Float] {
    callCount += 1
    XCTAssertEqual(melWindow.count, 76)
    return [Float](repeating: 0, count: 96)
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "testEmbeddingRunsWhenMelWindowFull|failed" | head
```
Expected: FAIL — `callCount` is 0 after the 76th frame (no embedding logic yet).

- [ ] **Step 3: Add the sliding-window logic to `process`**

In `WakeWordPipeline.swift`, replace the body of `process` with:

```swift
  func process(_ samples: [Float]) {
    audioBuffer.append(contentsOf: samples)
    while audioBuffer.count >= Self.audioStep {
      let chunk = Array(audioBuffer.prefix(Self.audioStep))
      audioBuffer.removeFirst(Self.audioStep)
      melBuffer.append(contentsOf: mel.extract(chunk))
      runEmbeddingsIfReady()
    }
  }

  private func runEmbeddingsIfReady() {
    while melBuffer.count >= Self.melWindow {
      let window = Array(melBuffer.prefix(Self.melWindow))
      embeddingBuffer.append(embedding.embed(window))
      melBuffer.removeFirst(Self.melStep)
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "testEmbeddingRunsWhenMelWindowFull|Test suite|executed" | head
```
Expected: PASS.

- [ ] **Step 5: Commit + full suite**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift
git commit -m "feat(voice): wakeword pipeline sliding mel window to embeddings"
bun run --filter '@raro/mobile' test
```

---

## Task 3: `WakeWordPipeline` — classifier, thresholds, debounce → WakeCommand

**Files:**
- Modify: `apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift`
- Test: `apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift`

- [ ] **Step 1: Write the failing tests (threshold pin-exact + debounce)**

Append to `WakeWordPipelineTests.swift`:

```swift
extension WakeWordPipelineTests {
  private func filledPipeline(gravarScore: Float, pararScore: Float,
                              onCommand: @escaping (WakeCommand) -> Void) -> WakeWordPipeline {
    let g = FakeClassifier(); g.fixedScore = gravarScore
    let p = FakeClassifier(); p.fixedScore = pararScore
    let pipeline = WakeWordPipeline(
      mel: FakeMel(), embedding: FakeEmbedding(),
      gravar: g, parar: p, gravarThreshold: 0.34, pararThreshold: 0.23
    )
    pipeline.onCommand = onCommand
    return pipeline
  }

  func testGravarFiresAtOrAboveThreshold() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.35, pararScore: 0.0) { cmds.append($0) }
    // 76 + 15*8 = 196 mel frames => 16 embeddings; each frame = 1280 samples.
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    XCTAssertEqual(cmds, [.start], "0.35 >= 0.34 fires start")
  }

  func testGravarDoesNotFireBelowThreshold() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.33, pararScore: 0.0) { cmds.append($0) }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    XCTAssertEqual(cmds, [], "0.33 < 0.34 does not fire")
  }

  func testPararFiresAtThreshold() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.0, pararScore: 0.24) { cmds.append($0) }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    XCTAssertEqual(cmds, [.stop], "0.24 >= 0.23 fires stop")
  }

  func testDebounceCollapsesRepeatWithinWindow() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.9, pararScore: 0.0) { cmds.append($0) }
    // Feed enough audio to cross threshold many consecutive times.
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    pipeline.process([Float](repeating: 0.1, count: 1280 * 8))
    XCTAssertEqual(cmds, [.start], "repeated crossings within debounce collapse to one")
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "Gravar|Parar|Debounce|onCommand|error:" | head
```
Expected: FAIL — `onCommand` property does not exist / no command logic.

- [ ] **Step 3: Add classifier + threshold + debounce logic**

In `WakeWordPipeline.swift`, add the property and extend the embedding loop:

```swift
  var onCommand: ((WakeCommand) -> Void)?
  private var firedFramesAgo = Int.max
  private static let debounceEmbeddings = 25  // ~2 s at 1 embedding / 80 ms

  private func runEmbeddingsIfReady() {
    while melBuffer.count >= Self.melWindow {
      let window = Array(melBuffer.prefix(Self.melWindow))
      embeddingBuffer.append(embedding.embed(window))
      melBuffer.removeFirst(Self.melStep)
      if embeddingBuffer.count > Self.embeddingCount {
        embeddingBuffer.removeFirst(embeddingBuffer.count - Self.embeddingCount)
      }
      firedFramesAgo = firedFramesAgo == Int.max ? Int.max : firedFramesAgo + 1
      classifyIfReady()
    }
  }

  private func classifyIfReady() {
    guard embeddingBuffer.count == Self.embeddingCount else { return }
    guard firedFramesAgo >= Self.debounceEmbeddings else { return }
    let gScore = gravar.classify(embeddingBuffer)
    let pScore = parar.classify(embeddingBuffer)
    if gScore >= gravarThreshold {
      onCommand?(.start)
      firedFramesAgo = 0
    } else if pScore >= pararThreshold {
      onCommand?(.stop)
      firedFramesAgo = 0
    }
  }
```

Note: `WakeCommand` is the existing Pigeon enum in `apps/mobile/ios/Runner/Native/Generated/VoiceApi.g.swift` (`enum WakeCommand: Int { case start = 0; case stop = 1 }`). It is `@testable import Runner`-visible. Do NOT redefine it.

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "Gravar|Parar|Debounce|Test suite|executed|failed" | head
```
Expected: 4 new tests pass.

- [ ] **Step 5: Commit + full suite**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add apps/mobile/ios/Runner/Native/Voice/WakeWordPipeline.swift apps/mobile/ios/RunnerTests/WakeWordPipelineTests.swift
git commit -m "feat(voice): wakeword pipeline thresholds and debounce to wakecommand"
bun run --filter '@raro/mobile' test
```

---

## Task 4: Insert the 4 `.onnx` into pbxproj (Copy Bundle Resources)

This closes the silent-bug debt from session 0026: without these insertions `Bundle.main.url(forResource:)` returns `nil`.

**Files:**
- Modify: `apps/mobile/ios/Runner.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add the 4 models to pbxproj**

For each of `melspectrogram.onnx`, `embedding_model.onnx`, `raro_gravar.onnx`, `raro_parar.onnx`, add (use IDs `…A0`/`…B0` … `…A3`/`…B3` — verify free first with `grep`):

1. **PBXFileReference** (group near other Resources): e.g.
   `CA00000000000000000000A0 /* melspectrogram.onnx */ = {isa = PBXFileReference; lastKnownFileType = file; path = melspectrogram.onnx; sourceTree = "<group>"; };`
2. **PBXBuildFile**:
   `CA00000000000000000000B0 /* melspectrogram.onnx in Resources */ = {isa = PBXBuildFile; fileRef = CA00000000000000000000A0 /* melspectrogram.onnx */; };`
3. Add the file ref to a **PBXGroup** named `Resources` under `Runner` (create the group if absent, parented to the Runner group).
4. Add the build-file ref to the **PBXResourcesBuildPhase** of the **Runner** target (`97C146EC1CF9000F007C117D` is the canonical Resources phase id — confirm by `grep "PBXResourcesBuildPhase" -A20`).

- [ ] **Step 2: Verify build picks them up (Simulator build, no codesign)**

```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --simulator --no-codesign 2>&1 | tail -5
```
Expected: `Xcode build done`. (Real bundle presence is asserted in Task 6 on device.)

- [ ] **Step 3: Commit**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "build(voice): wire 4 wakeword onnx models into copy bundle resources"
bun run --filter '@raro/mobile' test
```

---

## Task 5: `OnnxModelSession` — thin ORT wrapper (shared env, per-model EP)

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Voice/OnnxModelSession.swift`
- Test: `apps/mobile/ios/RunnerTests/OnnxModelSessionTests.swift`

- [ ] **Step 1: Write the failing test (load each of the 4 models from bundle + run a known buffer → finite score)**

`apps/mobile/ios/RunnerTests/OnnxModelSessionTests.swift`:

```swift
import XCTest
@testable import Runner

final class OnnxModelSessionTests: XCTestCase {
  func testAllFourModelsLoadFromBundle() throws {
    for name in ["melspectrogram", "embedding_model", "raro_gravar", "raro_parar"] {
      XCTAssertNoThrow(
        try OnnxModelSession(modelName: name, executionProvider: .cpu),
        "\(name).onnx must be in the app bundle (pbxproj Copy Bundle Resources)"
      )
    }
  }

  func testClassifierProducesFiniteScoreInRange() throws {
    let session = try OnnxModelSession(modelName: "raro_gravar", executionProvider: .cpu)
    let input = [Float](repeating: 0, count: 16 * 96)  // zeros => valid [1,16,96]
    let out = try session.run(input: input, inputName: "embeddings",
                              shape: [1, 16, 96], outputName: "score")
    XCTAssertEqual(out.count, 1)
    XCTAssertFalse(out[0].isNaN, "score must not be NaN")
    XCTAssertTrue(out[0] >= 0 && out[0] <= 1, "score in [0,1], got \(out[0])")
  }
}
```

- [ ] **Step 2: Add both test files to pbxproj (4 insertions each)**

`OnnxModelSessionTests.swift`: IDs `…F8`/`…F9`. Same 4 insertions as Task 1 Step 2 (PBXBuildFile, PBXFileReference, PBXGroup of RunnerTests, Sources phase of RunnerTests).

- [ ] **Step 3: Run test to verify it fails**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "OnnxModelSession|error:|cannot find" | head
```
Expected: FAIL — `cannot find 'OnnxModelSession'`.

- [ ] **Step 4: Write `OnnxModelSession.swift`**

`apps/mobile/ios/Runner/Native/Voice/OnnxModelSession.swift`:

```swift
import Foundation
import os.log
import onnxruntime

enum OnnxExecutionProvider {
  case cpu
  case coreML
}

final class OnnxModelSession {
  enum LoadError: Error { case modelNotFoundInBundle(String) }

  private static let env: ORTEnv = {
    // ORTEnv is process-global singleton (validated: ONNX Runtime docs).
    return try! ORTEnv(loggingLevel: .warning)
  }()
  private static let log = OSLog(subsystem: "com.rarocamera/voice", category: "onnx")

  private let session: ORTSession

  init(modelName: String, executionProvider: OnnxExecutionProvider) throws {
    guard let url = Bundle.main.url(forResource: modelName, withExtension: "onnx") else {
      throw LoadError.modelNotFoundInBundle(modelName)
    }
    let options = try ORTSessionOptions()
    if executionProvider == .coreML, ORTIsCoreMLExecutionProviderAvailable() {
      do {
        try options.appendCoreMLExecutionProvider(with: ORTCoreMLExecutionProviderOptions())
      } catch {
        os_log("CoreML EP unavailable for %{public}@, falling back to CPU: %{public}@",
               log: Self.log, type: .info, modelName, error.localizedDescription)
      }
    }
    session = try ORTSession(env: Self.env, modelPath: url.path, sessionOptions: options)
  }

  func run(input: [Float], inputName: String, shape: [NSNumber], outputName: String) throws -> [Float] {
    let data = input.withUnsafeBufferPointer { Data(buffer: $0) }
    let value = try ORTValue(tensorData: NSMutableData(data: data),
                             elementType: .float, shape: shape)
    let outputs = try session.run(withInputs: [inputName: value],
                                  outputNames: [outputName],
                                  runOptions: nil)
    guard let out = outputs[outputName] else { return [] }
    let outData = try out.tensorData() as Data
    return outData.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
  }
}
```

Note on the CoreML EP method name: the I/O contract records the validated symbol as `appendCoreMLExecutionProviderWithOptions:` (ObjC). If the Swift import surfaces it as `appendCoreMLExecutionProvider(with:)`, use that; if the device build rejects the signature, consult Context7 `/microsoft/onnxruntime-swift-package-manager` for the exact 1.24.2 selector before guessing. Do NOT silently skip the EP.

- [ ] **Step 5: Run test on device (serial — AVAudioEngine flakiness rule)**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "OnnxModelSessionTests|Test suite|executed|failed" | head
```
Expected: `Test Suite 'OnnxModelSessionTests' started` + both tests pass. If a model fails to load → pbxproj insertion missing (Task 4). If exit 0 but no `Test Suite started` line → false-green, the file is orphaned (re-check Step 2).

- [ ] **Step 6: Commit + full suite**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add apps/mobile/ios/Runner/Native/Voice/OnnxModelSession.swift apps/mobile/ios/RunnerTests/OnnxModelSessionTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(voice): onnx model session wrapper with per-model execution provider"
bun run --filter '@raro/mobile' test
```

---

## Task 6: `WakeWordDetector` façade — real ONNX adapters wired into the pipeline

Adapters bridge the real `OnnxModelSession` to the pipeline's protocols (mel normalization `x/10+2`, reshapes). The detector owns the 4 sessions + pipeline and exposes `process([Float])` + `onCommand`.

**Files:**
- Create: `apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift`
- Test: `apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift`

- [ ] **Step 1: Write the failing test (detector constructs + a known buffer runs the full chain to a finite score, no crash)**

`apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift`:

```swift
import XCTest
@testable import Runner

final class WakeWordDetectorTests: XCTestCase {
  func testDetectorConstructsWithBundledModels() {
    XCTAssertNoThrow(try WakeWordDetector())
  }

  func testFeedingSilenceDoesNotCrashAndDoesNotFalseFire() throws {
    let detector = try WakeWordDetector()
    var commands: [WakeCommand] = []
    detector.onCommand = { commands.append($0) }
    // ~2 s of silence (zeros) — must run the full mel->embed->classify chain without crashing.
    detector.process([Float](repeating: 0, count: 16000 * 2))
    XCTAssertTrue(commands.isEmpty, "pure silence must not trigger a wake command")
  }
}
```

- [ ] **Step 2: Add test file to pbxproj (4 insertions)**

`WakeWordDetectorTests.swift`: IDs `…FA`/`…FB`.

- [ ] **Step 3: Run test to verify it fails**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "WakeWordDetector|cannot find|error:" | head
```
Expected: FAIL — `cannot find 'WakeWordDetector'`.

- [ ] **Step 4: Write `WakeWordDetector.swift` with the ONNX adapters**

`apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift`:

```swift
import Foundation

private struct MelAdapter: MelExtracting {
  let session: OnnxModelSession
  func extract(_ samples: [Float]) -> [[Float]] {
    guard let raw = try? session.run(input: samples, inputName: "input",
                                     shape: [1, NSNumber(value: samples.count)],
                                     outputName: "output") else { return [] }
    // melspectrogram output is [T,1,?,32]; reshape to T rows of 32 bins, normalize x/10+2.
    let binCount = 32
    let frameCount = raw.count / binCount
    var frames: [[Float]] = []
    frames.reserveCapacity(frameCount)
    for f in 0..<frameCount {
      let start = f * binCount
      frames.append(raw[start..<start + binCount].map { $0 / 10 + 2 })
    }
    return frames
  }
}

private struct EmbeddingAdapter: Embedding {
  let session: OnnxModelSession
  func embed(_ melWindow: [[Float]]) -> [Float] {
    let flat = melWindow.flatMap { $0 }  // 76*32
    return (try? session.run(input: flat, inputName: "input_1",
                             shape: [1, 76, 32, 1], outputName: "conv2d_19")) ?? []
  }
}

private struct ClassifierAdapter: Classifying {
  let session: OnnxModelSession
  func classify(_ embeddings: [[Float]]) -> Float {
    let flat = embeddings.flatMap { $0 }  // 16*96
    let out = (try? session.run(input: flat, inputName: "embeddings",
                                shape: [1, 16, 96], outputName: "score")) ?? [0]
    return out.first ?? 0
  }
}

final class WakeWordDetector {
  private let pipeline: WakeWordPipeline

  var onCommand: ((WakeCommand) -> Void)? {
    get { pipeline.onCommand }
    set { pipeline.onCommand = newValue }
  }

  init() throws {
    let mel = MelAdapter(session: try OnnxModelSession(modelName: "melspectrogram", executionProvider: .cpu))
    let embedding = EmbeddingAdapter(session: try OnnxModelSession(modelName: "embedding_model", executionProvider: .coreML))
    let gravar = ClassifierAdapter(session: try OnnxModelSession(modelName: "raro_gravar", executionProvider: .coreML))
    let parar = ClassifierAdapter(session: try OnnxModelSession(modelName: "raro_parar", executionProvider: .coreML))
    pipeline = WakeWordPipeline(
      mel: mel, embedding: embedding, gravar: gravar, parar: parar,
      gravarThreshold: 0.34, pararThreshold: 0.23
    )
  }

  func process(_ samples: [Float]) {
    pipeline.process(samples)
  }
}
```

- [ ] **Step 5: Run test on device to verify it passes**

```bash
cd apps/mobile && bun run --filter '@raro/mobile' test:ios 2>&1 | grep -iE "WakeWordDetectorTests|Test suite|executed|failed" | head
```
Expected: both tests pass, no crash on the full chain.

- [ ] **Step 6: Commit + full suite**

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add apps/mobile/ios/Runner/Native/Voice/WakeWordDetector.swift apps/mobile/ios/RunnerTests/WakeWordDetectorTests.swift apps/mobile/ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat(voice): wakeword detector facade wiring onnx adapters into pipeline"
bun run --filter '@raro/mobile' test
```

---

## Task 7: Device acceptance gate (ADR-0023) — owner connects iPhone 12

This is the official gate. It needs the physical device and the owner's live voice. The detector is exercised through a temporary probe (NOT wired to VoiceManager yet — that is the next session).

**Files:**
- Temporary: a debug hook to feed `AudioSessionCoordinator.onFrame` → `WakeWordDetector.process` and `os_log` on command (probe only; reverted at session end or kept behind a debug flag).

- [ ] **Step 1: Build + install profile build (debug doesn't run standalone — memory)**

```bash
cd apps/mobile && GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
  GIT_CONFIG_KEY_1=protocol.file.allow GIT_CONFIG_VALUE_1=always \
  flutter build ios --profile 2>&1 | tail -5
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app 2>&1 | grep -iE "App installed|installationURL"
```
**Confirm `App installed:` + a NEW container UUID BEFORE asking the owner to test** (memory `feedback_verify_device_install_before_test` — a stale binary once read as "fix didn't work").

- [ ] **Step 2: Capture device log while owner speaks**

Ask the owner (who has the iPhone connected) to say "Raro gravar" and "Raro parar" at several distances/intonations, plus play unrelated audio for false-positive measurement. Capture:

```bash
pymobiledevice3 syslog live --match Runner | grep -iE "wake|score|com.rarocamera/voice"
```

- [ ] **Step 3: Evaluate against the gate**

- Recall > 80% on "Raro gravar"/"Raro parar" → count `wake matched` vs attempts.
- False positives low on non-wake audio.
- Voice↔recording coexistence (foreground SFSpeech still works, no mic war).

**If it passes:** record evidence (log excerpt) for the session log; do NOT flip `_voiceEngineAvailable` yet (that belongs to the orchestration session). **If it fails:** Plano B — full batch 15000 / +voice_design_prompts 50-100 / real PT-BR recordings. **NEVER Picovoice.**

- [ ] **Step 4: Remove the temporary probe (no entropy left behind)**

Revert the debug hook (or gate it behind an explicit `#if DEBUG` probe flag). Commit:

```bash
cd /Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro
git add -A
git commit -m "chore(voice): remove wakeword device-probe instrumentation"
bun run --filter '@raro/mobile' test
```

---

## Self-review (run after the plan, before execution)

- **Spec coverage:** Architecture (3 units) → Tasks 1-3 (pipeline), Task 5 (OnnxModelSession), Task 6 (detector). Data flow → Tasks 1-3 + adapters Task 6. Bundle debt → Task 4. Test strategy 3 layers → Tasks 1-3 (L1), 5-6 (L2), 7 (L3). Gate → Task 7. EP per model → Task 5/6. Shapes Step 0 → Task 0. All covered.
- **Placeholders:** none — every code step has full code; `<UDID>` is a runtime device value, not a code placeholder.
- **Type consistency:** `MelExtracting.extract`, `Embedding.embed`, `Classifying.classify`, `WakeWordPipeline(mel:embedding:gravar:parar:gravarThreshold:pararThreshold:)`, `OnnxModelSession.run(input:inputName:shape:outputName:)`, `WakeCommand{.start,.stop}` (existing Pigeon enum) — consistent across Tasks 1, 3, 5, 6.
- **Known risk flagged inline:** CoreML EP selector name (Task 5 Step 4 note) — resolve via Context7 if the Swift signature differs, never silently skip.

---

## References

- Spec: `docs/superpowers/specs/2026-06-14-wakeword-detector-swift-design.md`
- I/O contract: `docs/superpowers/notes/raro-model-training.md`
- ADR-0023; memories: `raro-pattern-wakeword-onnx-3stage-pipeline-shapes`, `raro-pattern-ios-xctest-pbxproj-4-insertions`, `raro-pattern-ios-audioengine-xctest-flaky-parallel-sim`, `feedback_verify_device_install_before_test`, `raro-pattern-spm-safe-bare-repository-sandbox`
