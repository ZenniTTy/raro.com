import Foundation
@preconcurrency import AVFoundation
import os.log

final class AudioSessionCoordinator {
  let targetSampleRate: Double = 16000
  let targetChannels: AVAudioChannelCount = 1
  var onFrame: (([Float]) -> Void)?
  var onInterruptionBegan: (() -> Void)?
  var onShouldRestart: (() -> Void)?

  private let log = OSLog(subsystem: "com.rarocamera/voice", category: "audio")
  private let engine = AVAudioEngine()
  private var converter: AVAudioConverter?
  private var running = false
  private let queue = DispatchQueue(label: "com.rarocamera.voice.audio")

  private let emitLock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
  private var emitting = false

  private func setEmitting(_ value: Bool) {
    os_unfair_lock_lock(emitLock)
    emitting = value
    os_unfair_lock_unlock(emitLock)
  }

  private func isEmitting() -> Bool {
    os_unfair_lock_lock(emitLock)
    let value = emitting
    os_unfair_lock_unlock(emitLock)
    return value
  }

  init() {
    emitLock.initialize(to: os_unfair_lock())

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleConfigChange(_:)),
      name: .AVAudioEngineConfigurationChange,
      object: engine
    )
  }

  func start() -> Bool {
    if queue.sync(execute: { running }) {
      return true
    }
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .measurement,
        options: [.mixWithOthers, .allowBluetooth]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      os_log("session setup failed: %{public}@", log: log, type: .error, error.localizedDescription)
      return false
    }
    let input = engine.inputNode
    let inFormat = input.outputFormat(forBus: 0)
    guard inFormat.sampleRate > 0, inFormat.channelCount > 0,
          let outFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: false
          ) else {
      os_log(
        "invalid input format sr=%f ch=%d",
        log: log,
        type: .error,
        inFormat.sampleRate,
        Double(inFormat.channelCount)
      )
      return false
    }
    converter = AVAudioConverter(from: inFormat, to: outFormat)
    let raised = ObjCExceptionCatcher.catchException {
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: inFormat) { [weak self] buffer, _ in
        self?.handleBuffer(buffer, outFormat: outFormat)
      }
      self.engine.prepare()
    }
    if let raised = raised {
      os_log("installTap raised: %{public}@", log: log, type: .error, raised.localizedDescription)
      return false
    }
    do {
      try engine.start()
    } catch {
      os_log("engine start failed: %{public}@", log: log, type: .error, error.localizedDescription)
      input.removeTap(onBus: 0)
      converter = nil
      return false
    }
    queue.sync { running = true }
    setEmitting(true)
    return true
  }

  func stop() {
    queue.sync {
      guard running else { return }
      setEmitting(false)
      engine.inputNode.removeTap(onBus: 0)
      engine.stop()
      running = false
      converter = nil
    }
  }

  private func handleBuffer(_ buffer: AVAudioPCMBuffer, outFormat: AVAudioFormat) {
    guard isEmitting() else { return }
    guard let converter = converter,
          let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: 4096) else { return }
    var consumed = false
    var error: NSError?
    converter.convert(to: out, error: &error) { _, status in
      if consumed {
        status.pointee = .noDataNow
        return nil
      }
      consumed = true
      status.pointee = .haveData
      return buffer
    }
    if let error = error {
      os_log("convert error: %{public}@", log: log, type: .error, error.localizedDescription)
      return
    }
    guard let channel = out.floatChannelData?[0] else { return }
    let frames = Array(UnsafeBufferPointer(start: channel, count: Int(out.frameLength)))
    onFrame?(frames)
  }

  @objc private func handleInterruption(_ note: Notification) {
    guard let info = note.userInfo,
          let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
    if type == .began {
      onInterruptionBegan?()
    } else {
      onShouldRestart?()
    }
  }

  @objc private func handleConfigChange(_ note: Notification) {
    let active = queue.sync { running }
    guard active else { return }
    os_log("engine config change — delegating restart", log: log, type: .info)
    onShouldRestart?()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    emitLock.deinitialize(count: 1)
    emitLock.deallocate()
  }
}
