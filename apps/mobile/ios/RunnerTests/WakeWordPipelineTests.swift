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

private final class CountingEmbedding: Embedding {
  var callCount = 0
  func embed(_ melWindow: [[Float]]) -> [Float] {
    callCount += 1
    XCTAssertEqual(melWindow.count, 76)
    return [Float](repeating: 0, count: 96)
  }
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
      raro: FakeClassifier(), raroThreshold: 0.5
    )
    pipeline.process([Float](repeating: 0.1, count: 1279))
    XCTAssertEqual(mel.callCount, 0, "1279 samples must NOT trigger mel")
    pipeline.process([Float](repeating: 0.1, count: 1))
    XCTAssertEqual(mel.callCount, 1, "1280th sample triggers mel")
    XCTAssertEqual(mel.lastInputCount, 1280)
  }

  func testMultipleChunksDrainInOneCall() {
    let mel = FakeMel()
    let pipeline = WakeWordPipeline(
      mel: mel, embedding: FakeEmbedding(),
      raro: FakeClassifier(), raroThreshold: 0.5
    )
    pipeline.process([Float](repeating: 0.1, count: 1280 * 2 + 100))
    XCTAssertEqual(mel.callCount, 2, "2560+100 samples drain to exactly 2 mel calls, 100 residual")
  }
}

extension WakeWordPipelineTests {
  func testEmbeddingRunsWhenMelWindowFull() {
    let mel = FakeMel()
    let embedding = CountingEmbedding()
    let pipeline = WakeWordPipeline(
      mel: mel, embedding: embedding,
      raro: FakeClassifier(), raroThreshold: 0.5
    )
    pipeline.process([Float](repeating: 0.1, count: 1280 * 75))
    XCTAssertEqual(embedding.callCount, 0, "75 frames < 76 window: no embedding yet")
    pipeline.process([Float](repeating: 0.1, count: 1280))
    XCTAssertEqual(embedding.callCount, 1, "76th frame fills the window")
  }
}

extension WakeWordPipelineTests {
  private func filledPipeline(raroScore: Float,
                              onWake: @escaping () -> Void) -> WakeWordPipeline {
    let r = FakeClassifier(); r.fixedScore = raroScore
    let pipeline = WakeWordPipeline(
      mel: FakeMel(), embedding: FakeEmbedding(),
      raro: r, raroThreshold: 0.5
    )
    pipeline.onWake = onWake
    return pipeline
  }

  func testRaroFiresAtOrAboveThreshold() {
    var wakes = 0
    let pipeline = filledPipeline(raroScore: 0.51) { wakes += 1 }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    XCTAssertEqual(wakes, 1, "0.51 >= 0.5 fires wake")
  }

  func testRaroDoesNotFireBelowThreshold() {
    var wakes = 0
    let pipeline = filledPipeline(raroScore: 0.49) { wakes += 1 }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    XCTAssertEqual(wakes, 0, "0.49 < 0.5 does not fire")
  }

  func testDebounceBlocksRefireWithinWindow() {
    var wakes = 0
    let pipeline = filledPipeline(raroScore: 0.9) { wakes += 1 }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    for _ in 0..<19 { pipeline.process([Float](repeating: 0.1, count: 1280 * 8)) }
    XCTAssertEqual(wakes, 1, "19 embeddings after fire: still debounced")
  }

  func testDebounceAllowsRefireAfterWindow() {
    var wakes = 0
    let pipeline = filledPipeline(raroScore: 0.9) { wakes += 1 }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    for _ in 0..<20 { pipeline.process([Float](repeating: 0.1, count: 1280 * 8)) }
    XCTAssertEqual(wakes, 2, "20th embedding after fire: debounce lifts, refires")
  }

  func testEmbeddingBufferStaysBounded() {
    let pipeline = filledPipeline(raroScore: 0.0) { }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 1000))
    XCTAssertTrue(pipeline.embeddingBufferCountForTesting <= 16,
                  "embeddingBuffer bounded to last 16, got \(pipeline.embeddingBufferCountForTesting)")
  }
}
