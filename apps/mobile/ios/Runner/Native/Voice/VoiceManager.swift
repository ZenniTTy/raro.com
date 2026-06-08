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

  private let wakeWord: String
  private let recognizer: SFSpeechRecognizer?
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var wantsListening = false
  private var engineRunning = false
  private var backoff: TimeInterval = 0
  private let queue = DispatchQueue(label: "com.rarocamera.voice")

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
      self.teardownEngine()
      DispatchQueue.main.async { self.onStateChanged?(.idle) }
    }
  }

  private func startListeningInternal() {
    guard wantsListening else { return }
    if isRecordingActive?() == true {
      backoff = 0
      teardownRecognition()
      teardownEngine()
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      scheduleRecordingPoll()
      return
    }
    guard let recognizer = recognizer, recognizer.isAvailable else {
      DispatchQueue.main.async { self.onStateChanged?(.unavailable) }
      scheduleErrorRetry()
      return
    }
    if !engineRunning {
      guard ensureEngineRunning() else {
        DispatchQueue.main.async { self.onStateChanged?(.paused) }
        scheduleErrorRetry()
        return
      }
    }
    guard beginRecognitionCycle(recognizer) else {
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      scheduleErrorRetry()
      return
    }
    backoff = 0
    DispatchQueue.main.async { self.onStateChanged?(.listening) }
  }

  private func ensureEngineRunning() -> Bool {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .defaultToSpeaker])
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      os_log("voice session config failed: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      return false
    }
    let input = audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else {
      os_log("voice engine — invalid input format sr=%f ch=%d",
             log: voiceLog, type: .error, format.sampleRate, Double(format.channelCount))
      return false
    }
    let raised = ObjCExceptionCatcher.catchException {
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        self?.request?.append(buffer)
      }
      self.audioEngine.prepare()
    }
    if let raised = raised {
      os_log("voice tap install raised: %{public}@", log: voiceLog, type: .error, raised.localizedDescription)
      return false
    }
    do {
      try audioEngine.start()
    } catch {
      os_log("voice engine start failed: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      input.removeTap(onBus: 0)
      return false
    }
    engineRunning = true
    return true
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
          if cmd == .start {
            self.backoff = 0
            self.teardownRecognition()
            self.teardownEngine()
            DispatchQueue.main.async { self.onStateChanged?(.paused) }
            self.scheduleRecordingPoll()
          } else {
            self.cycleRecognition()
          }
        }
        return
      }
      if error != nil || (result?.isFinal ?? false) {
        self.queue.async { self.cycleRecognition() }
      }
    }
    return true
  }

  private func cycleRecognition() {
    guard wantsListening else { return }
    if isRecordingActive?() == true {
      backoff = 0
      teardownRecognition()
      teardownEngine()
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      scheduleRecordingPoll()
      return
    }
    guard engineRunning, let recognizer = recognizer else {
      startListeningInternal()
      return
    }
    if beginRecognitionCycle(recognizer) {
      DispatchQueue.main.async { self.onStateChanged?(.listening) }
    } else {
      teardownRecognition(); teardownEngine()
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      scheduleErrorRetry()
    }
  }

  private func scheduleErrorRetry() {
    guard wantsListening else { return }
    backoff = min(max(backoff * 2, 1), 60)
    queue.asyncAfter(deadline: .now() + backoff) { [weak self] in
      self?.startListeningInternal()
    }
  }

  private func scheduleRecordingPoll() {
    guard wantsListening else { return }
    queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.startListeningInternal()
    }
  }

  private func teardownRecognition() {
    task?.cancel(); task = nil
    request?.endAudio(); request = nil
  }

  private func teardownEngine() {
    if audioEngine.isRunning { audioEngine.stop() }
    audioEngine.inputNode.removeTap(onBus: 0)
    engineRunning = false
  }
}
