@preconcurrency import AVFoundation
import Foundation
import os.log

private let recordingLog = OSLog(subsystem: "com.rarocamera", category: "recording")

enum RecordingPipelineError: Error {
  case notAttached
  case alreadyRecording
  case notRecording
  case writerSetupFailed(String)
}

final class RecordingPipeline: NSObject, @unchecked Sendable {
  private let videoOutput = AVCaptureVideoDataOutput()
  private let audioOutput = AVCaptureAudioDataOutput()
  private let outputQueue = DispatchQueue(label: "com.rarocamera.recording.output")

  private var writer: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var audioInput: AVAssetWriterInput?
  private var sessionStarted = false
  private var outputURL: URL?
  private var startedAt: CFTimeInterval = 0
  private var requestedCodec: String = "h265"
  private var recording = false
  var replayFps: Int = 60

  var onFinished: ((URL, Int) -> Void)?
  var onFailed: ((String) -> Void)?
  var replayConsumer: ((CMSampleBuffer, Bool) -> Void)?
  var audioSampleConsumer: ((CMSampleBuffer) -> Void)?
  var sharedQueue: DispatchQueue { outputQueue }

  func makeReplayVideoSettings() -> [String: Any] {
    var settings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4) ?? [:]
    settings[AVVideoCodecKey] = Self.selectCodec(
      requested: requestedCodec, available: videoOutput.availableVideoCodecTypes)
    return Self.injectKeyframeInterval(into: settings, chunkSeconds: 1, fps: replayFps)
  }

  static func injectKeyframeInterval(
    into settings: [String: Any],
    chunkSeconds: Int,
    fps: Int
  ) -> [String: Any] {
    var result = settings
    var compression = (result[AVVideoCompressionPropertiesKey] as? [String: Any]) ?? [:]
    compression[AVVideoMaxKeyFrameIntervalKey as String] = max(1, fps * chunkSeconds)
    compression[AVVideoMaxKeyFrameIntervalDurationKey as String] = Double(chunkSeconds)
    result[AVVideoCompressionPropertiesKey] = compression
    return result
  }

  func makeReplayAudioSettings() -> [String: Any]? {
    return audioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mp4) as? [String: Any]
  }

  var isRecording: Bool { outputQueue.sync { recording } }

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
    return dir.appendingPathComponent("raro_\(sessionId).mp4")
  }

  func attach(to session: AVCaptureSession) throws {
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
    guard session.canAddOutput(videoOutput) else {
      throw RecordingPipelineError.notAttached
    }
    session.addOutput(videoOutput)

    audioOutput.setSampleBufferDelegate(self, queue: outputQueue)
    if session.canAddOutput(audioOutput) {
      session.addOutput(audioOutput)
      os_log("recording audio data output attached", log: recordingLog, type: .info)
    } else {
      os_log("recording audio data output cannot be added", log: recordingLog, type: .error)
    }

    if let connection = videoOutput.connection(with: .video) {
      if connection.isVideoOrientationSupported {
        connection.videoOrientation = .portrait
      }
    }
    os_log("recording video data output attached", log: recordingLog, type: .info)
  }

  func start(sessionId: String, requestedCodec: String) throws {
    try outputQueue.sync {
      guard !recording else { throw RecordingPipelineError.alreadyRecording }
      let url = Self.makeOutputURL(sessionId: sessionId)
      try? FileManager.default.removeItem(at: url)

      let newWriter: AVAssetWriter
      do {
        newWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
      } catch {
        throw RecordingPipelineError.writerSetupFailed(error.localizedDescription)
      }

      let codec = Self.selectCodec(
        requested: requestedCodec,
        available: videoOutput.availableVideoCodecTypes
      )
      var videoSettings = videoOutput.recommendedVideoSettingsForAssetWriter(
        writingTo: .mp4
      ) ?? [:]
      videoSettings[AVVideoCodecKey] = codec
      let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
      vInput.expectsMediaDataInRealTime = true
      guard newWriter.canAdd(vInput) else {
        throw RecordingPipelineError.writerSetupFailed("cannot add video input")
      }
      newWriter.add(vInput)

      let audioSettings = audioOutput.recommendedAudioSettingsForAssetWriter(
        writingTo: .mp4
      )
      let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
      aInput.expectsMediaDataInRealTime = true
      if newWriter.canAdd(aInput) {
        newWriter.add(aInput)
      } else {
        os_log("recording audio input unavailable — video only", log: recordingLog, type: .error)
      }

      self.writer = newWriter
      self.videoInput = vInput
      self.audioInput = aInput
      self.outputURL = url
      self.sessionStarted = false
      self.requestedCodec = requestedCodec
      self.startedAt = CACurrentMediaTime()
      self.recording = true

      newWriter.startWriting()
      os_log(
        "recording started id=%{public}@ codec=%{public}@",
        log: recordingLog, type: .info, sessionId, "\(codec.rawValue)"
      )
    }
  }

  func stop() throws {
    try outputQueue.sync {
      guard recording, let writer = writer else {
        throw RecordingPipelineError.notRecording
      }
      recording = false
      let durationMs = Int((CACurrentMediaTime() - startedAt) * 1000)
      videoInput?.markAsFinished()
      audioInput?.markAsFinished()

      if writer.status == .failed {
        let message = writer.error?.localizedDescription ?? "writer failed"
        os_log("recording writer failed: %{public}@", log: recordingLog, type: .error, message)
        cleanup()
        DispatchQueue.main.async { [weak self] in self?.onFailed?(message) }
        return
      }

      let url = outputURL
      writer.finishWriting { [weak self] in
        guard let self = self else { return }
        let status = writer.status
        self.outputQueue.async {
          self.cleanup()
        }
        DispatchQueue.main.async {
          if status == .completed, let url = url {
            os_log(
              "recording finished path=%{public}@ durationMs=%d",
              log: recordingLog, type: .info, url.path, durationMs
            )
            self.onFinished?(url, durationMs)
          } else {
            let message = writer.error?.localizedDescription ?? "finish failed"
            os_log("recording finish failed: %{public}@", log: recordingLog, type: .error, message)
            self.onFailed?(message)
          }
        }
      }
      os_log("recording stop requested", log: recordingLog, type: .info)
    }
  }

  private func cleanup() {
    writer = nil
    videoInput = nil
    audioInput = nil
    outputURL = nil
    sessionStarted = false
  }
}

extension RecordingPipeline: AVCaptureVideoDataOutputSampleBufferDelegate,
  AVCaptureAudioDataOutputSampleBufferDelegate
{
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
    let isVideo = output === videoOutput
    replayConsumer?(sampleBuffer, isVideo)
    if !isVideo { audioSampleConsumer?(sampleBuffer) }

    guard recording, let writer = writer, writer.status == .writing else { return }

    let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

    if !sessionStarted {
      guard isVideo else { return }
      writer.startSession(atSourceTime: pts)
      sessionStarted = true
      os_log("recording session source time anchored", log: recordingLog, type: .debug)
    }

    if isVideo {
      if let input = videoInput, input.isReadyForMoreMediaData {
        if !input.append(sampleBuffer) {
          os_log(
            "recording video append failed status=%d error=%{public}@",
            log: recordingLog, type: .error,
            writer.status.rawValue, writer.error?.localizedDescription ?? "unknown"
          )
        }
      }
    } else {
      if let input = audioInput, input.isReadyForMoreMediaData {
        _ = input.append(sampleBuffer)
      }
    }
  }
}
