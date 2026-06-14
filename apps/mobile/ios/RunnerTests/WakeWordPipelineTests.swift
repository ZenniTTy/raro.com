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
      gravar: FakeClassifier(), parar: FakeClassifier(),
      gravarThreshold: 0.34, pararThreshold: 0.23
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
      gravar: FakeClassifier(), parar: FakeClassifier(),
      gravarThreshold: 0.34, pararThreshold: 0.23
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
      gravar: FakeClassifier(), parar: FakeClassifier(),
      gravarThreshold: 0.34, pararThreshold: 0.23
    )
    pipeline.process([Float](repeating: 0.1, count: 1280 * 75))
    XCTAssertEqual(embedding.callCount, 0, "75 frames < 76 window: no embedding yet")
    pipeline.process([Float](repeating: 0.1, count: 1280))
    XCTAssertEqual(embedding.callCount, 1, "76th frame fills the window")
  }
}

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

  func testDebounceBlocksRefireWithinWindow() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.9, pararScore: 0.0) { cmds.append($0) }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    for _ in 0..<19 { pipeline.process([Float](repeating: 0.1, count: 1280 * 8)) }
    XCTAssertEqual(cmds, [.start], "19 embeddings after fire: still debounced")
  }

  func testDebounceAllowsRefireAfterWindow() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.9, pararScore: 0.0) { cmds.append($0) }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 196))
    for _ in 0..<20 { pipeline.process([Float](repeating: 0.1, count: 1280 * 8)) }
    XCTAssertEqual(cmds, [.start, .start], "20th embedding after fire: debounce lifts, refires")
  }

  func testEmbeddingBufferStaysBounded() {
    var cmds: [WakeCommand] = []
    let pipeline = filledPipeline(gravarScore: 0.0, pararScore: 0.0) { cmds.append($0) }
    pipeline.process([Float](repeating: 0.1, count: 1280 * 1000))
    XCTAssertTrue(pipeline.embeddingBufferCountForTesting <= 16,
                  "embeddingBuffer bounded to last 16, got \(pipeline.embeddingBufferCountForTesting)")
  }
}
