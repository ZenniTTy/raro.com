@preconcurrency import AVFoundation
import Foundation
import os.log

private let cameraLog = OSLog(subsystem: "com.rarocamera", category: "camera")

final class CameraManager {
  private let sessionQueue = DispatchQueue(label: "com.rarocamera.session")
  private(set) var session: AVCaptureSession?
  private var device: AVCaptureDevice?
  private var input: AVCaptureDeviceInput?

  var onLensSwitched: ((LensType) -> Void)?
  var onError: ((CameraNativeError) -> Void)?

  func hasPermission() -> Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }

  func requestPermission() async -> Bool {
    await AVCaptureDevice.requestAccess(for: .video)
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

    return CameraCapabilities(
      availableLenses: lenses,
      supportedResolutions: [.hd720, .fhd1080, .uhd4k],
      supportedFps: [.fps30, .fps60]
    )
  }

  func startSession(config: CameraConfig) async throws {
    if session != nil { throw CameraNativeError.alreadyRunning }
    guard hasPermission() else { throw CameraNativeError.permissionDenied }

    let device = try selectDevice(for: config.lens)
    os_log(
      "startSession lens=%{public}@ chosenDeviceType=%{public}@ initialZoom=%.2f",
      log: cameraLog, type: .default,
      "\(config.lens)", "\(device.deviceType.rawValue)",
      Double(truncating: NSNumber(value: device.videoZoomFactor))
    )

    let session = AVCaptureSession()
    session.beginConfiguration()
    session.sessionPreset = .inputPriority
    let input = try AVCaptureDeviceInput(device: device)
    if session.canAddInput(input) { session.addInput(input) }
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: config.resolution, fps: config.fps)
    device.unlockForConfiguration()
    session.commitConfiguration()

    self.session = session
    self.device = device
    self.input = input

    let capturedSession = session
    await withCheckedContinuation { continuation in
      sessionQueue.async {
        capturedSession.startRunning()
        continuation.resume()
      }
    }
  }

  func stopSession() {
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

  func switchLens(_ lens: LensType) throws {
    guard let session = session else { throw CameraNativeError.notRunning }
    guard let currentDevice = self.device else { throw CameraNativeError.notRunning }

    os_log(
      "switchLens requested lens=%{public}@ currentDeviceType=%{public}@ minZoom=%.2f maxZoom=%.2f currentZoom=%.2f",
      log: cameraLog, type: .default,
      "\(lens)", "\(currentDevice.deviceType.rawValue)",
      Double(truncating: NSNumber(value: currentDevice.minAvailableVideoZoomFactor)),
      Double(truncating: NSNumber(value: currentDevice.maxAvailableVideoZoomFactor)),
      Double(truncating: NSNumber(value: currentDevice.videoZoomFactor))
    )

    let isVirtualMultiLens =
      currentDevice.deviceType == .builtInTripleCamera
      || currentDevice.deviceType == .builtInDualWideCamera

    if isVirtualMultiLens {
      let targetZoom: CGFloat = lens == .ultraWide ? 0.5 : 1.0
      let clamped = max(
        currentDevice.minAvailableVideoZoomFactor,
        min(targetZoom, currentDevice.maxAvailableVideoZoomFactor)
      )
      os_log(
        "switchLens path=zoom-ramp targetZoom=%.2f clamped=%.2f",
        log: cameraLog, type: .default,
        Double(truncating: NSNumber(value: targetZoom)),
        Double(truncating: NSNumber(value: clamped))
      )
      try currentDevice.lockForConfiguration()
      currentDevice.ramp(toVideoZoomFactor: clamped, withRate: 4.0)
      currentDevice.unlockForConfiguration()
      onLensSwitched?(lens)
      return
    }

    let newDevice = try selectDevice(for: lens)
    if newDevice.uniqueID == currentDevice.uniqueID {
      os_log("switchLens path=same-device-noop", log: cameraLog, type: .default)
      onLensSwitched?(lens)
      return
    }
    os_log(
      "switchLens path=replace-input newDeviceType=%{public}@",
      log: cameraLog, type: .default,
      "\(newDevice.deviceType.rawValue)"
    )
    session.beginConfiguration()
    if let oldInput = self.input { session.removeInput(oldInput) }
    let newInput = try AVCaptureDeviceInput(device: newDevice)
    if session.canAddInput(newInput) { session.addInput(newInput) }
    session.commitConfiguration()
    self.device = newDevice
    self.input = newInput
    onLensSwitched?(lens)
  }

  func setFormat(resolution: Resolution, fps: Fps) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    guard let session = session else { throw CameraNativeError.notRunning }
    os_log(
      "setFormat requested resolution=%{public}@ fps=%{public}@",
      log: cameraLog, type: .default, "\(resolution)", "\(fps)"
    )
    session.beginConfiguration()
    session.sessionPreset = .inputPriority
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: resolution, fps: fps)
    let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    device.unlockForConfiguration()
    session.commitConfiguration()
    os_log(
      "setFormat applied activeFormat=%dx%d",
      log: cameraLog, type: .default,
      Int(dims.width), Int(dims.height)
    )
  }

  func focusAt(point: FocusPoint) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    guard device.isFocusPointOfInterestSupported else { return }
    try device.lockForConfiguration()
    device.focusPointOfInterest = CGPoint(x: point.x, y: point.y)
    device.focusMode = .autoFocus
    device.unlockForConfiguration()
  }

  private func selectDevice(for lens: LensType) throws -> AVCaptureDevice {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [
        .builtInTripleCamera, .builtInDualWideCamera,
        .builtInUltraWideCamera, .builtInWideAngleCamera,
      ],
      mediaType: .video,
      position: .back
    )

    if let virtual = discovery.devices.first(where: { device in
      device.deviceType == .builtInTripleCamera
        || device.deviceType == .builtInDualWideCamera
    }) {
      let targetZoom: CGFloat = lens == .ultraWide ? 0.5 : 1.0
      do {
        try virtual.lockForConfiguration()
        virtual.videoZoomFactor = max(
          virtual.minAvailableVideoZoomFactor,
          min(targetZoom, virtual.maxAvailableVideoZoomFactor)
        )
        virtual.unlockForConfiguration()
      } catch {
        os_log(
          "zoom hint failed (non-fatal): %{public}@",
          log: cameraLog, type: .info, error.localizedDescription
        )
      }
      return virtual
    }

    if lens == .ultraWide {
      if let ultra = discovery.devices.first(where: { device in
        device.deviceType == .builtInUltraWideCamera
      }) { return ultra }
      throw CameraNativeError.lensUnavailable
    }
    if let wide = discovery.devices.first(where: { device in
      device.deviceType == .builtInWideAngleCamera
    }) { return wide }
    throw CameraNativeError.lensUnavailable
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

    let formats = device.formats.filter { format in
      let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      let supportsRes = dims.width == targetWidth && dims.height == targetHeight
      let supportsFps = format.videoSupportedFrameRateRanges.contains { range in
        range.minFrameRate <= targetFps && range.maxFrameRate >= targetFps
      }
      return supportsRes && supportsFps
    }
    guard let chosen = formats.first else { throw CameraNativeError.formatUnsupported }
    device.activeFormat = chosen
    let duration = CMTime(value: 1, timescale: Int32(targetFps))
    device.activeVideoMinFrameDuration = duration
    device.activeVideoMaxFrameDuration = duration
  }
}
