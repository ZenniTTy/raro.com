@preconcurrency import AVFoundation
import Speech
import os.log

private let voiceLog = OSLog(subsystem: "com.rarocamera/voice", category: "wake")

enum VoiceCommand {
  case start
  case stop
}

enum VoiceCommandParser {
  static func parse(_ transcript: String, wakeWord: String) -> VoiceCommand? {
    let lower = transcript.lowercased()
    let wake = wakeWord.lowercased()
    guard lower.contains(wake) else { return nil }
    if lower.contains("parar") || lower.contains("encerrar") {
      return .stop
    }
    if lower.contains("gravar") || lower.contains("começar") || lower.contains("comecar") {
      return .start
    }
    return nil
  }
}

final class VoiceManager: NSObject {
  var onCommand: ((VoiceCommand) -> Void)?
  var onStateChanged: ((VoiceListeningState) -> Void)?
  var isRecordingActive: (() -> Bool)?
  var isCameraAudioActive: (() -> Bool)?

  private let wakeWord: String
  private let recognizer: SFSpeechRecognizer?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var wantsListening = false
  private var backoff: TimeInterval = 0
  private let queue = DispatchQueue(label: "com.rarocamera.voice")
  private let ownAudioEngine = AVAudioEngine()
  private var ownEngineRunning = false

  init(wakeWord: String, locale: Locale = Locale(identifier: "pt-BR")) {
    self.wakeWord = wakeWord
    self.recognizer = SFSpeechRecognizer(locale: locale)
    super.init()
  }

  func isAvailable(_ completion: @escaping (Bool) -> Void) {
    SFSpeechRecognizer.requestAuthorization { status in
      let speechOk = status == .authorized
      let onDevice = self.recognizer?.supportsOnDeviceRecognition ?? false
      let requestMic: (@escaping (Bool) -> Void) -> Void = { done in
        if #available(iOS 17.0, *) {
          AVAudioApplication.requestRecordPermission(completionHandler: done)
        } else {
          AVAudioSession.sharedInstance().requestRecordPermission(done)
        }
      }
      requestMic { micOk in
        completion(speechOk && onDevice && micOk)
      }
    }
  }

  func start() {
    queue.async {
      self.wantsListening = true
      self.startListeningInternal()
    }
  }

  func stop() {
    queue.async {
      self.wantsListening = false
      self.teardownRecognition()
      self.stopOwnAudioSource()
      DispatchQueue.main.async { self.onStateChanged?(.idle) }
    }
  }

  func appendCaptureAudio(_ sampleBuffer: CMSampleBuffer) {
    queue.async {
      guard self.wantsListening, let request = self.request else { return }
      request.appendAudioSampleBuffer(sampleBuffer)
    }
  }

  func cameraAudioStateChanged() {
    queue.async { self.ensureAudioSource() }
  }

  private func startListeningInternal() {
    guard wantsListening else { return }
    guard let recognizer = recognizer, recognizer.isAvailable else {
      DispatchQueue.main.async { self.onStateChanged?(.unavailable) }
      scheduleErrorRetry()
      return
    }
    ensureAudioSource()
    guard beginRecognitionCycle(recognizer) else {
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      scheduleErrorRetry()
      return
    }
    backoff = 0
    DispatchQueue.main.async { self.onStateChanged?(.listening) }
  }

  private func beginRecognitionCycle(_ recognizer: SFSpeechRecognizer) -> Bool {
    task?.cancel(); task = nil
    request?.endAudio(); request = nil
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    self.request = request
    self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      guard let self = self else { return }
      if let result = result,
         let cmd = VoiceCommandParser.parse(result.bestTranscription.formattedString, wakeWord: self.wakeWord) {
        os_log("wake matched: %{public}@", log: voiceLog, type: .info, "\(cmd)")
        DispatchQueue.main.async { self.onCommand?(cmd) }
        self.queue.async {
          self.backoff = 0
          self.cycleRecognition()
        }
        return
      }
      if let error = error as NSError? {
        let code = error.code
        if code == 1101 || code == 1107 {
          os_log("speech service error (XPC) code=%d: %{public}@",
                 log: voiceLog, type: .error, code, error.localizedDescription)
        } else {
          os_log("recognition cycle ended code=%d (benign, recycling)",
                 log: voiceLog, type: .info, code)
        }
        self.queue.async { self.scheduleSilenceRecycle() }
      } else if result?.isFinal ?? false {
        self.queue.async { self.scheduleSilenceRecycle() }
      }
    }
    return true
  }

  private func scheduleSilenceRecycle() {
    guard wantsListening else { return }
    teardownRecognition()
    queue.asyncAfter(deadline: .now() + 0.4) { [weak self] in
      self?.startListeningInternal()
    }
  }

  private func cycleRecognition() {
    teardownRecognition()
    startListeningInternal()
  }

  private func scheduleErrorRetry() {
    guard wantsListening else { return }
    backoff = min(max(backoff * 2, 1), 60)
    queue.asyncAfter(deadline: .now() + backoff) { [weak self] in
      self?.startListeningInternal()
    }
  }

  private func teardownRecognition() {
    task?.cancel(); task = nil
    request?.endAudio(); request = nil
  }

  private func ensureAudioSource() {
    let cameraActive = isCameraAudioActive?() ?? false
    if cameraActive {
      if ownEngineRunning {
        os_log("audio source -> camera capture", log: voiceLog, type: .info)
        stopOwnAudioSource()
      }
    } else {
      if !ownEngineRunning {
        os_log("audio source -> own engine (camera stopped)", log: voiceLog, type: .info)
        _ = startOwnAudioSource()
      }
    }
  }

  private func configureSharedAudioSessionIfNeeded() {
    let session = AVAudioSession.sharedInstance()
    guard session.category != .playAndRecord else { return }
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.mixWithOthers, .defaultToSpeaker]
      )
      try session.setActive(true)
      os_log("shared audio session configured (.playAndRecord/.mixWithOthers)", log: voiceLog, type: .info)
    } catch {
      os_log("shared audio session setup failed: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
    }
  }

  private func startOwnAudioSource() -> Bool {
    configureSharedAudioSessionIfNeeded()
    let input = ownAudioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    let raised = ObjCExceptionCatcher.catchException {
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        guard let self = self else { return }
        self.queue.async {
          guard self.wantsListening, let request = self.request else { return }
          request.append(buffer)
        }
      }
      self.ownAudioEngine.prepare()
    }
    if let raised = raised {
      os_log("own installTap raised: %{public}@", log: voiceLog, type: .error, raised.localizedDescription)
      input.removeTap(onBus: 0)
      return false
    }
    do {
      try ownAudioEngine.start()
    } catch {
      os_log("own engine start failed: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      input.removeTap(onBus: 0)
      return false
    }
    ownEngineRunning = true
    return true
  }

  private func stopOwnAudioSource() {
    if ownAudioEngine.isRunning { ownAudioEngine.stop() }
    ownAudioEngine.inputNode.removeTap(onBus: 0)
    ownEngineRunning = false
  }
}
