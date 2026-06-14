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
