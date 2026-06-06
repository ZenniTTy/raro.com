@preconcurrency import AVFoundation
import Foundation
import os.log

struct Chunk {
  let url: URL
  let durationMs: Int
}

struct ReplayRing {
  private(set) var chunks: [Chunk] = []
  private(set) var capacityCount: Int
  let chunkSeconds: Int

  init(windowSeconds: Int, chunkSeconds: Int) {
    self.chunkSeconds = chunkSeconds
    self.capacityCount = Self.capacity(windowSeconds: windowSeconds, chunkSeconds: chunkSeconds)
  }

  static func capacity(windowSeconds: Int, chunkSeconds: Int) -> Int {
    guard chunkSeconds > 0 else { return 1 }
    return Int((Double(windowSeconds) / Double(chunkSeconds)).rounded(.up)) + 1
  }

  mutating func append(_ chunk: Chunk) -> [URL] {
    chunks.append(chunk)
    var evicted: [URL] = []
    while chunks.count > capacityCount {
      evicted.append(chunks.removeFirst().url)
    }
    return evicted
  }

  mutating func setWindow(seconds: Int) -> [URL] {
    capacityCount = Self.capacity(windowSeconds: seconds, chunkSeconds: chunkSeconds)
    var evicted: [URL] = []
    while chunks.count > capacityCount {
      evicted.append(chunks.removeFirst().url)
    }
    return evicted
  }

  func windowChunks() -> [Chunk] {
    return chunks
  }

  mutating func reset() -> [URL] {
    let urls = chunks.map { $0.url }
    chunks.removeAll()
    return urls
  }
}
