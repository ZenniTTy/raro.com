import Foundation
import os.log

private let voiceLog = OSLog(subsystem: "com.rarocamera/voice", category: "wakeword")

private struct MelAdapter: MelExtracting {
  let session: OnnxModelSession
  func extract(_ samples: [Float]) -> [[Float]] {
    let raw: [Float]
    do {
      raw = try session.run(input: samples, inputName: "input",
                            shape: [1, NSNumber(value: samples.count)],
                            outputName: "output")
    } catch {
      os_log("mel extract failed: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      return []
    }
    let binCount = 32
    if raw.count % binCount != 0 {
      os_log("mel output not multiple of 32: %d", log: voiceLog, type: .error, raw.count)
    }
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
    do {
      return try session.run(input: flat, inputName: "input_1",
                             shape: [1, 76, 32, 1], outputName: "conv2d_19")
    } catch {
      os_log("embedding failed: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      return []
    }
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

  var onScoresForTesting: ((Float, Float) -> Void)? {
    get { pipeline.onScoresForTesting }
    set { pipeline.onScoresForTesting = newValue }
  }

  init(classifierProvider: OnnxExecutionProvider = .coreML) throws {
    let mel = MelAdapter(session: try OnnxModelSession(modelName: "melspectrogram", executionProvider: .cpu))
    let embedding = EmbeddingAdapter(session: try OnnxModelSession(modelName: "embedding_model", executionProvider: classifierProvider))
    let gravar = ClassifierAdapter(session: try OnnxModelSession(modelName: "raro_gravar", executionProvider: classifierProvider))
    let parar = ClassifierAdapter(session: try OnnxModelSession(modelName: "raro_parar", executionProvider: classifierProvider))
    pipeline = WakeWordPipeline(
      mel: mel, embedding: embedding, gravar: gravar, parar: parar,
      gravarThreshold: 0.34, pararThreshold: 0.23
    )
  }

  func process(_ samples: [Float]) {
    pipeline.process(samples)
  }
}
