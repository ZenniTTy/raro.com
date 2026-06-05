@preconcurrency import AVFoundation
import Foundation
import os.log

private let cameraLog = OSLog(subsystem: "com.rarocamera", category: "camera")

final class CameraManager {
  private let sessionQueue = DispatchQueue(label: "com.rarocamera.session")
  private(set) var session: AVCaptureSession?
  private var device: AVCaptureDevice?
  private var input: AVCaptureDeviceInput?
  private var notificationTokens: [NSObjectProtocol] = []
  private var focusKVO: NSKeyValueObservation?
  private var focusDebounceWorkItem: DispatchWorkItem?
  private var focusTimeoutWorkItem: DispatchWorkItem?
  private var focusWasAdjusting = false
  private var pendingFocusPoint: FocusPoint?
  private var isInterrupted = false
  var onFocusResult: ((FocusPoint, Bool) -> Void)?

  var onLensSwitched: ((LensType) -> Void)?
  var onError: ((CameraNativeError) -> Void)?

  private let recordingPipeline = RecordingPipeline()

  deinit {
    removeObservers()
  }

  private func installObservers(for session: AVCaptureSession) {
    removeObservers()
    let nc = NotificationCenter.default
    notificationTokens.append(
      nc.addObserver(
        forName: AVCaptureSession.wasInterruptedNotification,
        object: session,
        queue: .main
      ) { [weak self] note in
        let reason = note.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int ?? -1
        os_log("session interrupted reason=%d", log: cameraLog, type: .info, reason)
        self?.isInterrupted = true
      }
    )
    notificationTokens.append(
      nc.addObserver(
        forName: AVCaptureSession.interruptionEndedNotification,
        object: session,
        queue: .main
      ) { [weak self] _ in
        os_log("session interruption ended — resuming", log: cameraLog, type: .info)
        self?.isInterrupted = false
        self?.sessionQueue.async { [weak self] in
          guard let self = self, let s = self.session, !s.isRunning else { return }
          s.startRunning()
        }
      }
    )
    notificationTokens.append(
      nc.addObserver(
        forName: AVCaptureSession.runtimeErrorNotification,
        object: session,
        queue: .main
      ) { [weak self] note in
        let err = note.userInfo?[AVCaptureSessionErrorKey] as? NSError
        os_log(
          "session runtime error code=%d %{public}@",
          log: cameraLog, type: .error,
          err?.code ?? 0, err?.localizedDescription ?? "unknown"
        )
        if err?.code == AVError.mediaServicesWereReset.rawValue {
          self?.sessionQueue.async { [weak self] in
            guard let self = self, let s = self.session, !s.isRunning else { return }
            s.startRunning()
          }
        } else {
          self?.onError?(.sessionFailed(err?.localizedDescription ?? "runtime error"))
        }
      }
    )
  }

  private func removeObservers() {
    for token in notificationTokens {
      NotificationCenter.default.removeObserver(token)
    }
    notificationTokens.removeAll()
  }

  func hasPermission() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }

  func requestPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      return true
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
      return false
    @unknown default:
      return false
    }
  }

  struct RawFormat: Hashable {
    let resolution: Resolution
    let fps: Fps
  }

  static func resolutionForDimensions(width: Int32, height: Int32) -> Resolution? {
    let longer = max(width, height)
    let shorter = min(width, height)
    switch (longer, shorter) {
    case (3840, 2160): return .uhd4k
    case (1920, 1080): return .fhd1080
    case (1280, 720): return .hd720
    default: return nil
    }
  }

  static func mergeFormatCapabilities(
    virtual: Set<RawFormat>,
    physical: Set<RawFormat>
  ) -> [FormatCapability] {
    var result: [FormatCapability] = []
    var seen: Set<RawFormat> = []
    let order: [(Resolution, Fps)] = [
      (.hd720, .fps30), (.hd720, .fps60),
      (.fhd1080, .fps30), (.fhd1080, .fps60),
      (.uhd4k, .fps30), (.uhd4k, .fps60),
    ]
    for (resolution, fps) in order {
      let raw = RawFormat(resolution: resolution, fps: fps)
      if virtual.contains(raw) {
        seen.insert(raw)
        result.append(
          FormatCapability(resolution: resolution, fps: fps, requiresPhysicalLens: false)
        )
      }
    }
    for (resolution, fps) in order {
      let raw = RawFormat(resolution: resolution, fps: fps)
      if seen.contains(raw) { continue }
      if physical.contains(raw) {
        result.append(
          FormatCapability(resolution: resolution, fps: fps, requiresPhysicalLens: true)
        )
      }
    }
    return result
  }

  private static func rawFormats(of device: AVCaptureDevice) -> Set<RawFormat> {
    var formats: Set<RawFormat> = []
    for format in device.formats {
      let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      guard
        let resolution = resolutionForDimensions(width: dims.width, height: dims.height)
      else { continue }
      let supports30 = format.videoSupportedFrameRateRanges.contains {
        $0.minFrameRate <= 30 && $0.maxFrameRate >= 30
      }
      let supports60 = format.videoSupportedFrameRateRanges.contains {
        $0.minFrameRate <= 60 && $0.maxFrameRate >= 60
      }
      if supports30 { formats.insert(RawFormat(resolution: resolution, fps: .fps30)) }
      if supports60 { formats.insert(RawFormat(resolution: resolution, fps: .fps60)) }
    }
    return formats
  }

  func discoverCapabilities() throws -> CameraCapabilities {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [
        .builtInTripleCamera,
        .builtInDualWideCamera,
        .builtInUltraWideCamera,
        .builtInWideAngleCamera,
      ],
      mediaType: .video,
      position: .back
    )
    let devices = discovery.devices
    if devices.isEmpty { throw CameraNativeError.deviceUnavailable }

    var lenses: [LensType] = []
    if devices.contains(where: { device in
      device.deviceType == .builtInTripleCamera
        || device.deviceType == .builtInDualWideCamera
        || device.deviceType == .builtInUltraWideCamera
    }) {
      lenses.append(.ultraWide)
    }
    if devices.contains(where: { device in
      device.deviceType == .builtInWideAngleCamera
        || device.deviceType == .builtInTripleCamera
        || device.deviceType == .builtInDualWideCamera
    }) {
      lenses.append(.wide)
    }

    let virtualDevice = devices.first {
      $0.deviceType == .builtInTripleCamera || $0.deviceType == .builtInDualWideCamera
    }
    let physicalDevice = devices.first { $0.deviceType == .builtInWideAngleCamera }

    let virtualFormats = virtualDevice.map(Self.rawFormats) ?? []
    let physicalFormats = physicalDevice.map(Self.rawFormats) ?? []
    let supportedFormats = Self.mergeFormatCapabilities(
      virtual: virtualFormats,
      physical: physicalFormats
    )

    return CameraCapabilities(
      availableLenses: lenses,
      supportedFormats: supportedFormats
    )
  }

  func startSession(config: CameraConfig) async throws {
    if let existing = session {
      os_log("startSession called while session exists — stopping previous", log: cameraLog, type: .default)
      removeObservers()
      existing.stopRunning()
      session = nil
      device = nil
      input = nil
    }
    isInterrupted = false
    guard hasPermission() else { throw CameraNativeError.permissionDenied }

    let device = try selectDevice(
      for: config.lens,
      resolution: config.resolution,
      fps: config.fps
    )
    os_log(
      "startSession lens=%{public}@ device=%{public}@",
      log: cameraLog, type: .info,
      "\(config.lens)", "\(device.deviceType.rawValue)"
    )

    let session = AVCaptureSession()
    session.beginConfiguration()
    session.sessionPreset = .inputPriority
    let input = try AVCaptureDeviceInput(device: device)
    if session.canAddInput(input) { session.addInput(input) }
    if let audioDevice = AVCaptureDevice.default(for: .audio) {
      do {
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        if session.canAddInput(audioInput) {
          session.addInput(audioInput)
          os_log("audio input added", log: cameraLog, type: .info)
        } else {
          os_log("audio input cannot be added", log: cameraLog, type: .error)
        }
      } catch {
        os_log("audio input failed: %{public}@", log: cameraLog, type: .error, error.localizedDescription)
      }
    } else {
      os_log("no audio device available", log: cameraLog, type: .info)
    }
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: config.resolution, fps: config.fps)
    device.unlockForConfiguration()
    session.commitConfiguration()

    let isVirtual =
      device.deviceType == .builtInTripleCamera
      || device.deviceType == .builtInDualWideCamera
    if isVirtual {
      applyVirtualLensZoom(device: device, lens: config.lens)
    }

    self.session = session
    self.device = device
    self.input = input
    installObservers(for: session)
    installFocusKVO(on: device)

    let capturedSession = session
    let capturedPipeline = recordingPipeline
    await withCheckedContinuation { continuation in
      sessionQueue.async {
        capturedSession.beginConfiguration()
        do {
          try capturedPipeline.attach(to: capturedSession)
        } catch {
          os_log("recording attach failed: %{public}@", log: cameraLog, type: .error, error.localizedDescription)
        }
        capturedSession.commitConfiguration()
        capturedSession.startRunning()
        continuation.resume()
      }
    }
  }

  func stopSession() {
    removeObservers()
    focusKVO?.invalidate()
    focusKVO = nil
    focusDebounceWorkItem?.cancel()
    focusDebounceWorkItem = nil
    focusTimeoutWorkItem?.cancel()
    focusTimeoutWorkItem = nil
    focusWasAdjusting = false
    pendingFocusPoint = nil
    sessionQueue.async { [weak self] in
      self?.session?.stopRunning()
      if let inputs = self?.session?.inputs {
        for input in inputs { self?.session?.removeInput(input) }
      }
      self?.session = nil
      self?.device = nil
      self?.input = nil
    }
  }

  func startRecording(sessionId: String, codec: String) throws {
    guard session != nil else { throw CameraNativeError.notRunning }
    guard !isInterrupted else { throw CameraNativeError.sessionInterrupted }
    try recordingPipeline.start(sessionId: sessionId, requestedCodec: codec)
  }

  func stopRecording() throws {
    try recordingPipeline.stop()
  }

  var onRecordingFinished: ((URL, Int) -> Void)? {
    get { recordingPipeline.onFinished }
    set { recordingPipeline.onFinished = newValue }
  }

  var onRecordingFailed: ((String) -> Void)? {
    get { recordingPipeline.onFailed }
    set { recordingPipeline.onFailed = newValue }
  }

  func switchLens(_ lens: LensType) throws {
    guard let session = session else { throw CameraNativeError.notRunning }
    guard let currentDevice = self.device else { throw CameraNativeError.notRunning }

    let isVirtual =
      currentDevice.deviceType == .builtInTripleCamera
      || currentDevice.deviceType == .builtInDualWideCamera

    if isVirtual {
      applyVirtualLensZoom(device: currentDevice, lens: lens)
      onLensSwitched?(lens)
      return
    }

    let newDevice = try selectDevice(for: lens)
    if newDevice.uniqueID == currentDevice.uniqueID {
      onLensSwitched?(lens)
      return
    }
    os_log(
      "switchLens lens=%{public}@ %{public}@->%{public}@",
      log: cameraLog, type: .info,
      "\(lens)", "\(currentDevice.deviceType.rawValue)", "\(newDevice.deviceType.rawValue)"
    )
    session.beginConfiguration()
    if let oldInput = self.input { session.removeInput(oldInput) }
    let newInput = try AVCaptureDeviceInput(device: newDevice)
    if session.canAddInput(newInput) { session.addInput(newInput) }
    session.sessionPreset = .inputPriority
    session.commitConfiguration()
    self.device = newDevice
    self.input = newInput
    onLensSwitched?(lens)
  }

  func setFormat(resolution: Resolution, fps: Fps) throws {
    guard let currentDevice = device else { throw CameraNativeError.notRunning }
    guard let session = session else { throw CameraNativeError.notRunning }
    guard !isInterrupted else { throw CameraNativeError.sessionInterrupted }
    guard !recordingPipeline.isRecording else {
      throw CameraNativeError.sessionFailed("cannot change format while recording")
    }

    let targetDevice = try selectDevice(
      for: lensFor(device: currentDevice),
      resolution: resolution,
      fps: fps
    )

    session.beginConfiguration()
    session.sessionPreset = .inputPriority
    let activeDevice: AVCaptureDevice
    if targetDevice.uniqueID != currentDevice.uniqueID {
      if let oldInput = input { session.removeInput(oldInput) }
      let newInput = try AVCaptureDeviceInput(device: targetDevice)
      if session.canAddInput(newInput) {
        session.addInput(newInput)
      } else {
        session.commitConfiguration()
        throw CameraNativeError.formatUnsupported
      }
      self.device = targetDevice
      self.input = newInput
      activeDevice = targetDevice
    } else {
      activeDevice = currentDevice
    }

    do {
      try activeDevice.lockForConfiguration()
      defer { activeDevice.unlockForConfiguration() }
      try applyFormat(device: activeDevice, resolution: resolution, fps: fps)
    } catch {
      session.commitConfiguration()
      throw error
    }
    let dims = CMVideoFormatDescriptionGetDimensions(activeDevice.activeFormat.formatDescription)
    session.commitConfiguration()

    let switchedDevice = activeDevice.uniqueID != currentDevice.uniqueID
    if switchedDevice {
      installFocusKVO(on: activeDevice)
    }

    let activeIsVirtual =
      activeDevice.deviceType == .builtInTripleCamera
      || activeDevice.deviceType == .builtInDualWideCamera
    if switchedDevice && activeIsVirtual {
      applyVirtualLensZoom(device: activeDevice, lens: .wide)
      onLensSwitched?(.wide)
    }

    os_log(
      "setFormat %{public}@@%{public}@ device=%{public}@ -> %dx%d",
      log: cameraLog, type: .info,
      "\(resolution)", "\(fps)", "\(activeDevice.deviceType.rawValue)",
      Int(dims.width), Int(dims.height)
    )
  }

  private func lensFor(device: AVCaptureDevice) -> LensType {
    return device.deviceType == .builtInUltraWideCamera ? .ultraWide : .wide
  }

  func focusAt(sensorPoint: CGPoint, normalizedPoint: FocusPoint) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    try applyFocusConfig(device: device, sensorPoint: sensorPoint, normalizedPoint: normalizedPoint)
  }

  func focusAtAsync(
    sensorPoint: CGPoint,
    normalizedPoint: FocusPoint,
    completion: @escaping (CameraNativeError?) -> Void
  ) {
    sessionQueue.async { [weak self] in
      guard let self = self, let device = self.device else {
        completion(CameraNativeError.notRunning)
        return
      }
      do {
        try self.applyFocusConfig(device: device, sensorPoint: sensorPoint, normalizedPoint: normalizedPoint)
        completion(nil)
      } catch let err as CameraNativeError {
        completion(err)
      } catch {
        completion(CameraNativeError.sessionFailed(error.localizedDescription))
      }
    }
  }

  private func applyFocusConfig(
    device: AVCaptureDevice,
    sensorPoint: CGPoint,
    normalizedPoint: FocusPoint
  ) throws {
    guard device.isFocusPointOfInterestSupported else {
      os_log("focusAt skipped — device lacks isFocusPointOfInterestSupported", log: cameraLog, type: .info)
      return
    }
    try device.lockForConfiguration()
    if device.isSmoothAutoFocusSupported {
      device.isSmoothAutoFocusEnabled = false
    }
    device.focusPointOfInterest = sensorPoint
    device.focusMode = .autoFocus
    if device.isExposurePointOfInterestSupported {
      device.exposurePointOfInterest = sensorPoint
      device.exposureMode = .continuousAutoExposure
    }
    device.unlockForConfiguration()
    os_log(
      "focusAt applied sensor=(%.3f,%.3f) device=%{public}@",
      log: cameraLog, type: .info,
      sensorPoint.x, sensorPoint.y, "\(device.deviceType.rawValue)"
    )
    DispatchQueue.main.async { [weak self] in
      self?.armFocusObservation(for: normalizedPoint)
    }
  }

  private func installFocusKVO(on device: AVCaptureDevice) {
    focusKVO?.invalidate()
    focusKVO = device.observe(\.isAdjustingFocus, options: [.new]) { [weak self] _, change in
      let adjusting = change.newValue ?? false
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        guard let pendingPoint = self.pendingFocusPoint else { return }
        if adjusting {
          self.focusWasAdjusting = true
          return
        }
        guard self.focusWasAdjusting else { return }
        let work = DispatchWorkItem { [weak self] in
          guard let self = self else { return }
          self.focusTimeoutWorkItem?.cancel()
          self.focusTimeoutWorkItem = nil
          self.focusDebounceWorkItem = nil
          self.focusWasAdjusting = false
          self.pendingFocusPoint = nil
          self.onFocusResult?(pendingPoint, true)
        }
        self.focusDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016, execute: work)
      }
    }
  }

  private func armFocusObservation(for point: FocusPoint) {
    focusDebounceWorkItem?.cancel()
    focusTimeoutWorkItem?.cancel()
    focusWasAdjusting = false
    pendingFocusPoint = point
    let timeout = DispatchWorkItem { [weak self] in
      guard let self = self else { return }
      self.focusDebounceWorkItem?.cancel()
      self.focusDebounceWorkItem = nil
      self.focusTimeoutWorkItem = nil
      self.focusWasAdjusting = false
      self.pendingFocusPoint = nil
      self.onFocusResult?(point, false)
    }
    focusTimeoutWorkItem = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeout)
  }

  static func requiresPhysicalLens(resolution: Resolution?, fps: Fps?) -> Bool {
    return resolution == .uhd4k && fps == .fps60
  }

  private func selectDevice(
    for lens: LensType,
    resolution: Resolution? = nil,
    fps: Fps? = nil
  ) throws -> AVCaptureDevice {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [
        .builtInTripleCamera, .builtInDualWideCamera,
        .builtInUltraWideCamera, .builtInWideAngleCamera,
      ],
      mediaType: .video,
      position: .back
    )

    if Self.requiresPhysicalLens(resolution: resolution, fps: fps) {
      if let wide = discovery.devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
        return wide
      }
      throw CameraNativeError.formatUnsupported
    }

    if let virtual = discovery.devices.first(where: {
      $0.deviceType == .builtInTripleCamera || $0.deviceType == .builtInDualWideCamera
    }) {
      return virtual
    }

    if lens == .ultraWide {
      if let ultra = discovery.devices.first(where: { $0.deviceType == .builtInUltraWideCamera }) {
        return ultra
      }
      throw CameraNativeError.lensUnavailable
    }
    if let wide = discovery.devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
      return wide
    }
    throw CameraNativeError.lensUnavailable
  }

  private func applyVirtualLensZoom(device: AVCaptureDevice, lens: LensType) {
    let switchOver = device.virtualDeviceSwitchOverVideoZoomFactors.first?.doubleValue ?? 2.0
    let targetZoom: CGFloat
    switch lens {
    case .ultraWide:
      targetZoom = device.minAvailableVideoZoomFactor
    case .wide:
      targetZoom = CGFloat(switchOver)
    }
    let clamped = min(targetZoom, device.maxAvailableVideoZoomFactor)
    do {
      try device.lockForConfiguration()
      device.videoZoomFactor = clamped
      device.unlockForConfiguration()
      os_log(
        "applyVirtualLensZoom lens=%{public}@ zoom=%.2f switchOver=%.2f",
        log: cameraLog, type: .info,
        "\(lens)", Double(truncating: NSNumber(value: clamped)), switchOver
      )
    } catch {
      os_log("virtual zoom failed: %{public}@", log: cameraLog, type: .error, error.localizedDescription)
    }
  }

  private func applyFormat(
    device: AVCaptureDevice,
    resolution: Resolution,
    fps: Fps
  ) throws {
    let targetWidth: Int32
    let targetHeight: Int32
    switch resolution {
    case .hd720: targetWidth = 1280; targetHeight = 720
    case .fhd1080: targetWidth = 1920; targetHeight = 1080
    case .uhd4k: targetWidth = 3840; targetHeight = 2160
    }
    let targetFps: Double = fps == .fps60 ? 60 : 30

    let exactMatches = device.formats.filter { format in
      let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      let supportsRes = dims.width == targetWidth && dims.height == targetHeight
      let supportsFps = format.videoSupportedFrameRateRanges.contains { range in
        range.minFrameRate <= targetFps && range.maxFrameRate >= targetFps
      }
      return supportsRes && supportsFps
    }

    guard let chosen = exactMatches.first else {
      os_log(
        "applyFormat unsupported target=%dx%d@%.0f device=%{public}@",
        log: cameraLog, type: .error,
        Int(targetWidth), Int(targetHeight), targetFps,
        "\(device.deviceType.rawValue)"
      )
      throw CameraNativeError.formatUnsupported
    }
    device.activeFormat = chosen
    let duration = CMTime(value: 1, timescale: Int32(targetFps))
    device.activeVideoMinFrameDuration = duration
    device.activeVideoMaxFrameDuration = duration
    if device.isSmoothAutoFocusSupported {
      device.isSmoothAutoFocusEnabled = true
    }
    let chosenDims = CMVideoFormatDescriptionGetDimensions(chosen.formatDescription)
    os_log(
      "applyFormat chose dims=%dx%d binned=%{public}@ multicam=%{public}@",
      log: cameraLog, type: .debug,
      Int(chosenDims.width), Int(chosenDims.height),
      "\(chosen.isVideoBinned)", "\(chosen.isMultiCamSupported)"
    )
  }
}
