@preconcurrency import AVFoundation
import Foundation
import os.log

private let recordingLog = OSLog(subsystem: "com.rarocamera", category: "recording")

enum RecordingPipelineError: Error {
  case notAttached
  case alreadyRecording
  case notRecording
}

final class RecordingPipeline: NSObject {
  private var movieOutput: AVCaptureMovieFileOutput?
  private var startedAt: CFTimeInterval = 0
  private var currentSessionId: String?

  var onFinished: ((URL, Int) -> Void)?
  var onFailed: ((String) -> Void)?

  var isRecording: Bool { movieOutput?.isRecording ?? false }

  static func selectCodec(
    requested: String,
    available: [AVVideoCodecType]
  ) -> AVVideoCodecType {
    if requested == "h264" {
      return available.contains(.h264) ? .h264 : (available.first ?? .h264)
    }
    if available.contains(.hevc) { return .hevc }
    if available.contains(.h264) { return .h264 }
    return available.first ?? .hevc
  }

  static func makeOutputURL(sessionId: String) -> URL {
    let dir = FileManager.default.temporaryDirectory
    return dir.appendingPathComponent("raro_\(sessionId).mov")
  }

  func attach(to session: AVCaptureSession) throws {
    let output = AVCaptureMovieFileOutput()
    guard session.canAddOutput(output) else {
      throw RecordingPipelineError.notAttached
    }
    session.addOutput(output)
    movieOutput = output
    os_log("recording output attached", log: recordingLog, type: .info)
  }

  func start(sessionId: String, requestedCodec: String) throws {
    guard let output = movieOutput else { throw RecordingPipelineError.notAttached }
    guard !output.isRecording else { throw RecordingPipelineError.alreadyRecording }
    if let connection = output.connection(with: .video) {
      let codec = Self.selectCodec(
        requested: requestedCodec,
        available: output.availableVideoCodecTypes
      )
      output.setOutputSettings([AVVideoCodecKey: codec], for: connection)
      os_log("recording codec=%{public}@", log: recordingLog, type: .info, "\(codec.rawValue)")
    }
    let url = Self.makeOutputURL(sessionId: sessionId)
    do {
      try FileManager.default.removeItem(at: url)
    } catch {
      os_log("recording no stale file to remove", log: recordingLog, type: .debug)
    }
    currentSessionId = sessionId
    startedAt = CACurrentMediaTime()
    output.startRecording(to: url, recordingDelegate: self)
    os_log("recording started id=%{public}@", log: recordingLog, type: .info, sessionId)
  }

  func stop() throws {
    guard let output = movieOutput, output.isRecording else {
      throw RecordingPipelineError.notRecording
    }
    output.stopRecording()
    os_log("recording stop requested", log: recordingLog, type: .info)
  }
}

extension RecordingPipeline: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    let durationMs = Int((CACurrentMediaTime() - startedAt) * 1000)
    if let error = error {
      os_log(
        "recording failed: %{public}@",
        log: recordingLog, type: .error, error.localizedDescription
      )
      onFailed?(error.localizedDescription)
      return
    }
    os_log(
      "recording finished path=%{public}@ durationMs=%d",
      log: recordingLog, type: .info, outputFileURL.path, durationMs
    )
    onFinished?(outputFileURL, durationMs)
  }
}
