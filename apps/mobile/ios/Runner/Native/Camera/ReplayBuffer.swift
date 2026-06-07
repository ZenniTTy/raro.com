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

private let replayLog = OSLog(subsystem: "com.rarocamera", category: "replay")

enum ReplayBufferError: Error {
  case thermalThrottled
  case notBuffering
  case noChunks
  case exportFailed(String)

  var code: String {
    switch self {
    case .thermalThrottled: return "thermalThrottled"
    case .notBuffering: return "notBuffering"
    case .noChunks: return "noChunks"
    case .exportFailed: return "exportFailed"
    }
  }
  var message: String? {
    if case let .exportFailed(m) = self { return m }
    return nil
  }
}

final class ReplayBuffer: NSObject, @unchecked Sendable {
  private let queue: DispatchQueue
  private let chunkSeconds: Int
  private var ring: ReplayRing
  private var buffering = false
  private var paused = false
  private let finalizationGroup = DispatchGroup()

  private var writer: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var audioInput: AVAssetWriterInput?
  private var chunkStartedAt: CMTime?
  private var sessionStarted = false
  private var chunkIndex = 0
  private var videoSettings: [String: Any]?
  private var audioSettings: [String: Any]?

  var onSaved: ((URL, Int) -> Void)?
  var onFailed: ((ReplayBufferError) -> Void)?

  init(queue: DispatchQueue, windowSeconds: Int = 15, chunkSeconds: Int = 1) {
    self.queue = queue
    self.chunkSeconds = chunkSeconds
    self.ring = ReplayRing(windowSeconds: windowSeconds, chunkSeconds: chunkSeconds)
    super.init()
  }

  deinit {
    for url in ring.reset() { try? FileManager.default.removeItem(at: url) }
  }

  func start(videoSettings: [String: Any], audioSettings: [String: Any]?) {
    queue.async {
      guard ProcessInfo.processInfo.thermalState != .critical else {
        os_log("replay start refused — thermalState=critical(%d)", log: replayLog, type: .error,
               ProcessInfo.processInfo.thermalState.rawValue)
        DispatchQueue.main.async { self.onFailed?(.thermalThrottled) }
        return
      }
      self.videoSettings = videoSettings
      self.audioSettings = audioSettings
      self.buffering = true
      os_log("replay buffering started", log: replayLog, type: .info)
    }
  }

  func stop() {
    queue.async {
      self.buffering = false
      self.finishCurrentChunk(keep: false, endPts: nil)
      for url in self.ring.reset() { try? FileManager.default.removeItem(at: url) }
      os_log("replay buffering stopped", log: replayLog, type: .info)
    }
  }

  func setWindow(seconds: Int) {
    queue.async {
      for url in self.ring.setWindow(seconds: seconds) {
        try? FileManager.default.removeItem(at: url)
      }
    }
  }

  func reset() {
    queue.async {
      self.finishCurrentChunk(keep: false, endPts: nil)
      for url in self.ring.reset() { try? FileManager.default.removeItem(at: url) }
    }
  }

  static func shouldAppend(buffering: Bool, paused: Bool) -> Bool {
    return buffering && !paused
  }

  func append(_ sampleBuffer: CMSampleBuffer, isVideo: Bool) {
    guard Self.shouldAppend(buffering: buffering, paused: paused) else { return }
    guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
    let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

    if writer == nil { openChunk(at: pts) }
    guard let writer = writer else { return }

    if !sessionStarted {
      guard isVideo else { return }
      writer.startSession(atSourceTime: pts)
      sessionStarted = true
      chunkStartedAt = pts
    }
    if isVideo, let input = videoInput, input.isReadyForMoreMediaData {
      if !input.append(sampleBuffer) {
        os_log("replay video append failed status=%d", log: replayLog, type: .error, writer.status.rawValue)
      }
    } else if !isVideo, let input = audioInput, input.isReadyForMoreMediaData {
      if !input.append(sampleBuffer) {
        os_log("replay audio append failed", log: replayLog, type: .error)
      }
    }

    if let start = chunkStartedAt {
      let elapsed = CMTimeGetSeconds(CMTimeSubtract(pts, start))
      if elapsed >= Double(chunkSeconds), isVideo {
        rollChunk(nextPts: pts)
      }
    }
  }

  private func openChunk(at pts: CMTime) {
    guard let vSettings = videoSettings else { return }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("raro_replay_\(chunkIndex).mp4")
    try? FileManager.default.removeItem(at: url)
    chunkIndex += 1
    guard let newWriter = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return }
    let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: vSettings)
    vInput.expectsMediaDataInRealTime = true
    if newWriter.canAdd(vInput) { newWriter.add(vInput) }
    var aInput: AVAssetWriterInput?
    if let aSettings = audioSettings {
      let input = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
      input.expectsMediaDataInRealTime = true
      if newWriter.canAdd(input) { newWriter.add(input); aInput = input }
    }
    newWriter.startWriting()
    self.writer = newWriter
    self.videoInput = vInput
    self.audioInput = aInput
    self.sessionStarted = false
  }

  private func rollChunk(nextPts: CMTime) {
    finishCurrentChunk(keep: true, endPts: nextPts)
    openChunk(at: nextPts)
  }

  private func finishCurrentChunk(keep: Bool, endPts: CMTime?) {
    guard let writer = writer else { return }
    let url = writer.outputURL
    let durationMs: Int
    if let endPts = endPts, let start = chunkStartedAt {
      durationMs = Int(CMTimeGetSeconds(CMTimeSubtract(endPts, start)) * 1000)
    } else {
      durationMs = chunkSeconds * 1000
    }
    videoInput?.markAsFinished()
    audioInput?.markAsFinished()
    finalizationGroup.enter()
    writer.finishWriting { [weak self] in
      self?.finalizationGroup.leave()
    }
    self.writer = nil
    self.videoInput = nil
    self.audioInput = nil
    self.chunkStartedAt = nil
    self.sessionStarted = false
    if keep {
      for evicted in ring.append(Chunk(url: url, durationMs: max(durationMs, chunkSeconds * 1000))) {
        try? FileManager.default.removeItem(at: evicted)
      }
    } else {
      try? FileManager.default.removeItem(at: url)
    }
  }

  func save() {
    queue.async {
      guard self.buffering else { DispatchQueue.main.async { self.onFailed?(.notBuffering) }; return }
      self.finishCurrentChunk(keep: true, endPts: nil)
      let chunks = self.ring.windowChunks()
      guard !chunks.isEmpty else { DispatchQueue.main.async { self.onFailed?(.noChunks) }; return }
      self.finalizationGroup.notify(queue: self.queue) {
        self.export(chunks: chunks)
      }
    }
  }

  func pauseAppending() {
    queue.async { self.paused = true }
  }

  func resumeAppending() {
    queue.async { self.paused = false }
  }

  func snapshotChunks() -> [Chunk] {
    return queue.sync {
      guard self.buffering else { return [] }
      self.finishCurrentChunk(keep: true, endPts: nil)
      return self.ring.windowChunks()
    }
  }

  func exportCombined(
    prerollChunks: [Chunk],
    recording: Chunk,
    completion: @escaping (Result<(URL, Int), ReplayBufferError>) -> Void
  ) {
    queue.async {
      self.finalizationGroup.notify(queue: self.queue) {
        self.export(chunks: prerollChunks + [recording], completion: completion)
      }
    }
  }

  private func export(
    chunks: [Chunk],
    completion: ((Result<(URL, Int), ReplayBufferError>) -> Void)? = nil
  ) {
    let report: (Result<(URL, Int), ReplayBufferError>) -> Void = { result in
      DispatchQueue.main.async {
        if let completion = completion {
          completion(result)
          return
        }
        switch result {
        case let .success((url, durationMs)):
          self.onSaved?(url, durationMs)
        case let .failure(error):
          self.onFailed?(error)
        }
      }
    }

    let composition = AVMutableComposition()
    let videoTrack = composition.addMutableTrack(
      withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    let audioTrack = composition.addMutableTrack(
      withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    var cursor = CMTime.zero
    for chunk in chunks {
      let asset = AVURLAsset(url: chunk.url)
      guard let assetVideo = asset.tracks(withMediaType: .video).first else {
        os_log("replay export skipping chunk without video track: %{public}@",
               log: replayLog, type: .error, chunk.url.lastPathComponent)
        continue
      }
      let range = CMTimeRange(start: .zero, duration: asset.duration)
      do {
        try videoTrack?.insertTimeRange(range, of: assetVideo, at: cursor)
        if let assetAudio = asset.tracks(withMediaType: .audio).first {
          try audioTrack?.insertTimeRange(range, of: assetAudio, at: cursor)
        }
        cursor = CMTimeAdd(cursor, asset.duration)
      } catch {
        os_log("replay export insert failed for chunk %{public}@: %{public}@",
               log: replayLog, type: .error,
               chunk.url.lastPathComponent, error.localizedDescription)
      }
    }
    guard cursor > .zero else {
      os_log("replay export aborted — no usable chunks", log: replayLog, type: .error)
      report(.failure(.exportFailed("no usable chunks")))
      return
    }
    let outURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("raro_replay_\(UUID().uuidString).mp4")
    guard let export = AVAssetExportSession(
      asset: composition, presetName: AVAssetExportPresetPassthrough) else {
      report(.failure(.exportFailed("no export session")))
      return
    }
    export.outputURL = outURL
    export.outputFileType = .mp4
    let totalMs = Int(CMTimeGetSeconds(cursor) * 1000)
    export.exportAsynchronously {
      if export.status == .completed {
        os_log("replay export saved path=%{public}@ durationMs=%d", log: replayLog, type: .info, outURL.path, totalMs)
        report(.success((outURL, totalMs)))
      } else {
        let msg = export.error?.localizedDescription ?? "export failed"
        os_log("replay export failed: %{public}@", log: replayLog, type: .error, msg)
        report(.failure(.exportFailed(msg)))
      }
    }
  }
}
