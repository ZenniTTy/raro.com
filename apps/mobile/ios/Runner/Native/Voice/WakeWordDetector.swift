import Foundation

private struct MelAdapter: MelExtracting {
  let session: OnnxModelSession
  func extract(_ samples: [Float]) -> [[Float]] {
    guard let raw = try? session.run(input: samples, inputName: "input",
                                     shape: [1, NSNumber(value: samples.count)],
                                     outputName: "output") else { return [] }
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
    let flat = melWindow.flatMap { $0 }
    return (try? session.run(input: flat, inputName: "input_1",
                             shape: [1, 76, 32, 1], outputName: "conv2d_19")) ?? []
  }
}

private struct ClassifierAdapter: Classifying {
  let session: OnnxModelSession
  func classify(_ embeddings: [[Float]]) -> Float {
    let flat = embeddings.flatMap { $0 }
    let out = (try? session.run(input: flat, inputName: "embeddings",
                                shape: [1, 16, 96], outputName: "score")) ?? []
    guard let first = out.first, first.isFinite else { return 0 }
    return first
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
