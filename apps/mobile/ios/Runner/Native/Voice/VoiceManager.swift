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
      self.beginSession()
    }
  }

  func stop() {
    queue.async {
      self.wantsListening = false
      self.teardown()
      DispatchQueue.main.async { self.onStateChanged?(.idle) }
    }
  }

  private func beginSession() {
    guard wantsListening else { return }
    if isRecordingActive?() == true {
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      scheduleRestart()
      return
    }
    guard let recognizer = recognizer, recognizer.isAvailable else {
      DispatchQueue.main.async { self.onStateChanged?(.unavailable) }
      scheduleRestart()
      return
    }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.requiresOnDeviceRecognition = true
      request.shouldReportPartialResults = true
      self.request = request

      let input = audioEngine.inputNode
      let format = input.outputFormat(forBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        self?.request?.append(buffer)
      }
      audioEngine.prepare()
      try audioEngine.start()

      self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
        guard let self = self else { return }
        if let result = result,
           let cmd = VoiceCommandParser.parse(result.bestTranscription.formattedString, wakeWord: self.wakeWord) {
          os_log("wake matched: %{public}@", log: voiceLog, type: .info, "\(cmd)")
          DispatchQueue.main.async { self.onCommand?(cmd) }
          self.queue.async { self.restartSession() }
          return
        }
        if error != nil || (result?.isFinal ?? false) {
          self.queue.async { self.restartSession() }
        }
      }
      backoff = 0
      DispatchQueue.main.async { self.onStateChanged?(.listening) }
    } catch {
      os_log("voice session error: %{public}@", log: voiceLog, type: .error, error.localizedDescription)
      DispatchQueue.main.async { self.onStateChanged?(.paused) }
      teardown()
      scheduleRestart()
    }
  }

  private func restartSession() {
    teardown()
    guard wantsListening else { return }
    beginSession()
  }

  private func scheduleRestart() {
    guard wantsListening else { return }
    backoff = min(max(backoff * 2, 1), 60)
    queue.asyncAfter(deadline: .now() + backoff) { [weak self] in
      self?.beginSession()
    }
  }

  private func teardown() {
    task?.cancel(); task = nil
    request?.endAudio(); request = nil
    if audioEngine.isRunning { audioEngine.stop() }
    audioEngine.inputNode.removeTap(onBus: 0)
  }
}
