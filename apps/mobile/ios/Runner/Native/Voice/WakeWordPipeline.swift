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
  private let raro: Classifying
  private let raroThreshold: Float

  private static let audioStep = 1280
  private static let melWindow = 76
  private static let melStep = 8
  private static let embeddingCount = 16

  private var audioBuffer: [Float] = []
  private var melBuffer: [[Float]] = []
  private var embeddingBuffer: [[Float]] = []

  var onWake: (() -> Void)?
  var onScoreForTesting: ((Float) -> Void)?
  private var firedFramesAgo = Int.max
  private static let debounceEmbeddings = 20

  var embeddingBufferCountForTesting: Int { embeddingBuffer.count }

  init(mel: MelExtracting, embedding: Embedding,
       raro: Classifying, raroThreshold: Float) {
    self.mel = mel
    self.embedding = embedding
    self.raro = raro
    self.raroThreshold = raroThreshold
  }

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
      if embeddingBuffer.count > Self.embeddingCount {
        embeddingBuffer.removeFirst(embeddingBuffer.count - Self.embeddingCount)
      }
      if firedFramesAgo != Int.max { firedFramesAgo += 1 }
      classifyIfReady()
    }
  }

  private func classifyIfReady() {
    guard embeddingBuffer.count == Self.embeddingCount else { return }
    guard firedFramesAgo >= Self.debounceEmbeddings else { return }
    let score = raro.classify(embeddingBuffer)
    onScoreForTesting?(score)
    if score >= raroThreshold {
      onWake?()
      firedFramesAgo = 0
    }
  }
}
