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
