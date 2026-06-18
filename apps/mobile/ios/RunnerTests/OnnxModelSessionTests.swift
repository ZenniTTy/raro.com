import XCTest
@testable import Runner

final class OnnxModelSessionTests: XCTestCase {
  func testAllFourModelsLoadFromBundle() throws {
    for name in ["melspectrogram", "embedding_model", "raro_gravar", "raro_parar"] {
      XCTAssertNoThrow(
        try OnnxModelSession(modelName: name, executionProvider: .cpu),
        "\(name).onnx must be in the app bundle"
      )
    }
  }

  func testClassifierProducesFiniteScoreInRange() throws {
    let session = try OnnxModelSession(modelName: "raro_gravar", executionProvider: .cpu)
    let input = [Float](repeating: 0, count: 16 * 96)
    let out = try session.run(input: input, inputName: "embeddings",
                              shape: [1, 16, 96], outputName: "score")
    XCTAssertEqual(out.count, 1)
    XCTAssertFalse(out[0].isNaN, "score must not be NaN")
    XCTAssertTrue(out[0] >= 0 && out[0] <= 1, "score in [0,1], got \(out[0])")
  }
}
