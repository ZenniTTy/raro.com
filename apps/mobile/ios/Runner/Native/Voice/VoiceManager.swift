@preconcurrency import AVFoundation
import Speech
import os.log

private let voiceLog = OSLog(subsystem: "com.rarocamera/voice", category: "wake")

enum VoiceCommand: Equatable {
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
  private var lastCommand: VoiceCommand?
  private var lastCommandTime: Date?
  private let commandDebounceInterval: TimeInterval = 1.5
  private var refreshWorkItem: DispatchWorkItem?
  private let proactiveRefreshInterval: TimeInterval = 50
  private var activeCycle: UUID?
  private var recentAudio: [CMSampleBuffer] = []
  private let recentAudioMaxCount = 24
  private static let terminalErrorCodes: Set<Int> = [1101, 1107, 7, 4, 203, 1700]

  // ⚠️ BUILD DE TESTE — ONNX wake-word (background) LIGADO por padrao p/ o dono testar "Raro" ao vivo.
  // REVERTER para `false` (ou o check de arg/env) antes de qualquer commit de producao — SFSpeech fica off neste build.
  private let useOnnxEngine: Bool = true
  // BUILD DE TESTE (modelo v2 hibrido com voz real): limiar 0.35 calibrado pelo gate offline v2.
  // Picos de "Raro" na voz crua: melhores 0.43-0.50; iscas medianas ~0.14, ruido ~0.06.
  // 0.35 fica acima das iscas/ruido e pega os "Raro" fortes. Device CoreML/fp16 pode diferir do offline CPU.
  private let onnxTestThreshold: Float = 0.35
  private let wakeDetector: WakeWordDetector?
  private var voiceToggleOn = false
  private let onnxCoordinator = AudioSessionCoordinator()
  private var onnxCoordinatorRunning = false
  private var onnxFrameCount = 0

  init(wakeWord: String, locale: Locale = Locale(identifier: "pt-BR")) {
    self.wakeWord = wakeWord
    self.recognizer = SFSpeechRecognizer(locale: locale)
    self.wakeDetector = try? WakeWordDetector(raroThreshold: onnxTestThreshold)
    super.init()
    self.wakeDetector?.onWake = { [weak self] in
      self?.queue.async { self?.handleWakeToggle() }
    }
    self.wakeDetector?.onScoreForTesting = { score in
      if score >= 0.08 {
        os_log("onnx raro PEAK score=%.3f (candidate — speak 'Raro' to test trigger)", log: voiceLog, type: .info, score)
      }
    }
    self.onnxCoordinator.onFrame = { [weak self] frames in
      guard let self = self else { return }
      self.queue.async {
        guard self.wantsListening, !frames.isEmpty else { return }
        self.onnxFrameCount += 1
        if self.onnxFrameCount == 1 || self.onnxFrameCount % 200 == 0 {
          os_log("onnx frames flowing: count=%d (mic is HOT, audio reaching detector)", log: voiceLog, type: .info, self.onnxFrameCount)
        }
        self.wakeDetector?.process(frames)
      }
    }
    self.onnxCoordinator.onShouldRestart = { [weak self] in
      self?.queue.async { self?.restartOnnxCoordinator() }
    }
  }

  func isAvailable(_ completion: @escaping (Bool) -> Void) {
    let requestMic: (@escaping (Bool) -> Void) -> Void = { done in
      if #available(iOS 17.0, *) {
        AVAudioApplication.requestRecordPermission(completionHandler: done)
      } else {
        AVAudioSession.sharedInstance().requestRecordPermission(done)
      }
    }
    if useOnnxEngine {
      requestMic { micOk in
        os_log("isAvailable(onnx): micOk=%{public}@", log: voiceLog, type: .info, micOk ? "true" : "false")
        completion(micOk)
      }
      return
    }
    SFSpeechRecognizer.requestAuthorization { status in
      let speechOk = status == .authorized
      let onDevice = self.recognizer?.supportsOnDeviceRecognition ?? false
      requestMic { micOk in
        completion(speechOk && onDevice && micOk)
      }
    }
  }

  func start() {
    queue.async {
      os_log("VoiceManager.start() called — wantsListening=true, useOnnx=%{public}@", log: voiceLog, type: .info, self.useOnnxEngine ? "true" : "false")
      self.wantsListening = true
      self.startListeningInternal()
    }
  }

  func stop() {
    queue.async {
      self.wantsListening = false
      self.lastCommand = nil
      self.lastCommandTime = nil
      self.teardownRecognition()
      self.stopOwnAudioSource()
      if self.onnxCoordinatorRunning {
        self.onnxCoordinator.stop()
        self.onnxCoordinatorRunning = false
      }
      DispatchQueue.main.async { self.onStateChanged?(.idle) }
    }
  }

  func resumeIfNeeded() {
    onnxCoordinator.setLifecycleState(foreground: true)
    queue.async {
      guard self.wantsListening, self.useOnnxEngine else { return }
      if !self.onnxCoordinator.isRunning() {
        os_log("resumeIfNeeded: coordinator was stopped — restarting (lifecycle/interruption recovery)", log: voiceLog, type: .info)
        self.ensureAudioSource()
      }
    }
  }

  func markBackground() {
    onnxCoordinator.setLifecycleState(foreground: false)
  }

  func appendCaptureAudio(_ sampleBuffer: CMSampleBuffer) {
    queue.async {
      guard self.wantsListening else { return }
      self.retainRecentAudio(sampleBuffer)
      guard let request = self.request else { return }
      request.appendAudioSampleBuffer(sampleBuffer)
    }
  }

  func cameraAudioStateChanged() {
    queue.async { self.ensureAudioSource() }
  }

  private func startListeningInternal() {
    guard wantsListening else { return }
    if useOnnxEngine {
      os_log("voice engine = ONNX (background wake-word)", log: voiceLog, type: .info)
      ensureAudioSource()
      DispatchQueue.main.async { self.onStateChanged?(.listening) }
      return
    }
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
    for buffer in recentAudio {
      request.appendAudioSampleBuffer(buffer)
    }
    let cycleToken = UUID()
    self.activeCycle = cycleToken
    self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      guard let self = self else { return }
      if let result = result,
         let cmd = VoiceCommandParser.parse(result.bestTranscription.formattedString, wakeWord: self.wakeWord) {
        self.queue.async { self.handleDetectedCommand(cmd) }
        return
      }
      if let error = error as NSError? {
        let code = error.code
        if Self.terminalErrorCodes.contains(code) {
          os_log("speech service error (terminal) code=%d: %{public}@",
                 log: voiceLog, type: .error, code, error.localizedDescription)
          self.queue.async { self.refreshCycle(after: 0.4, token: cycleToken) }
        } else {
          os_log("recognition cycle ended code=%d (benign, refreshing)",
                 log: voiceLog, type: .info, code)
          self.queue.async { self.refreshCycle(after: 0, token: cycleToken) }
        }
      } else if result?.isFinal ?? false {
        self.queue.async { self.refreshCycle(after: 0, token: cycleToken) }
      }
    }
    scheduleProactiveRefresh(token: cycleToken)
    return true
  }

  private func refreshCycle(after delay: TimeInterval, token: UUID) {
    guard wantsListening, activeCycle == token else { return }
    activeCycle = nil
    refreshWorkItem?.cancel()
    let work = DispatchWorkItem { [weak self] in self?.startListeningInternal() }
    refreshWorkItem = work
    if delay <= 0 {
      queue.async(execute: work)
    } else {
      queue.asyncAfter(deadline: .now() + delay, execute: work)
    }
  }

  private func retainRecentAudio(_ sampleBuffer: CMSampleBuffer) {
    recentAudio.append(sampleBuffer)
    if recentAudio.count > recentAudioMaxCount {
      recentAudio.removeFirst(recentAudio.count - recentAudioMaxCount)
    }
  }

  private func scheduleProactiveRefresh(token: UUID) {
    queue.asyncAfter(deadline: .now() + proactiveRefreshInterval) { [weak self] in
      guard let self = self, self.wantsListening, self.activeCycle == token else { return }
      os_log("proactive refresh (avoid resource decay)", log: voiceLog, type: .info)
      self.refreshCycle(after: 0, token: token)
    }
  }

  private func handleDetectedCommand(_ cmd: VoiceCommand) {
    let now = Date()
    if let lastCommand = lastCommand,
       let lastCommandTime = lastCommandTime,
       lastCommand == cmd,
       now.timeIntervalSince(lastCommandTime) < commandDebounceInterval {
      os_log("command debounced: %{public}@", log: voiceLog, type: .info, "\(cmd)")
      return
    }
    lastCommand = cmd
    lastCommandTime = now
    backoff = 0
    recentAudio.removeAll()
    os_log("wake matched: %{public}@", log: voiceLog, type: .info, "\(cmd)")
    DispatchQueue.main.async { self.onCommand?(cmd) }
    let token = activeCycle ?? UUID()
    activeCycle = token
    refreshCycle(after: 0, token: token)
  }

  private func scheduleErrorRetry() {
    guard wantsListening else { return }
    backoff = min(max(backoff * 2, 1), 60)
    queue.asyncAfter(deadline: .now() + backoff) { [weak self] in
      self?.startListeningInternal()
    }
  }

  private func teardownRecognition() {
    activeCycle = nil
    refreshWorkItem?.cancel(); refreshWorkItem = nil
    recentAudio.removeAll()
    task?.cancel(); task = nil
    request?.endAudio(); request = nil
  }

  private func ensureAudioSource() {
    if useOnnxEngine {
      if !onnxCoordinator.isRunning() {
        os_log("audio source -> AudioSessionCoordinator (onnx dedicated, camera-independent, background-capable)", log: voiceLog, type: .info)
        onnxCoordinatorRunning = onnxCoordinator.start()
        if !onnxCoordinatorRunning {
          os_log("onnx coordinator failed to start", log: voiceLog, type: .error)
        }
      }
      return
    }
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

  private func restartOnnxCoordinator() {
    guard useOnnxEngine, wantsListening else { return }
    os_log("onnx coordinator restart (interruption/config change)", log: voiceLog, type: .info)
    onnxCoordinator.stop()
    onnxCoordinatorRunning = onnxCoordinator.start()
    if !onnxCoordinatorRunning {
      os_log("onnx coordinator restart failed", log: voiceLog, type: .error)
    }
  }

  private func handleWakeToggle() {
    let now = Date()
    if let lastCommandTime = lastCommandTime,
       now.timeIntervalSince(lastCommandTime) < 2.5 {
      os_log("onnx wake debounced", log: voiceLog, type: .info)
      return
    }
    lastCommandTime = now
    voiceToggleOn.toggle()
    let cmd: VoiceCommand = voiceToggleOn ? .start : .stop
    os_log("onnx wake matched -> %{public}@", log: voiceLog, type: .info, "\(cmd)")
    DispatchQueue.main.async { self.onCommand?(cmd) }
  }
}
