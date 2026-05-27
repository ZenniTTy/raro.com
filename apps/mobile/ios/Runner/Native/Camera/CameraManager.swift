import AVFoundation
import Foundation

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
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: config.resolution, fps: config.fps)
    device.unlockForConfiguration()

    let session = AVCaptureSession()
    session.beginConfiguration()
    let input = try AVCaptureDeviceInput(device: device)
    if session.canAddInput(input) { session.addInput(input) }
    session.commitConfiguration()

    self.session = session
    self.device = device
    self.input = input

    await withCheckedContinuation { continuation in
      sessionQueue.async {
        session.startRunning()
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
    let newDevice = try selectDevice(for: lens)
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
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: resolution, fps: fps)
    device.unlockForConfiguration()
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

    if lens == .ultraWide {
      if let virtual = discovery.devices.first(where: { device in
        device.deviceType == .builtInTripleCamera
          || device.deviceType == .builtInDualWideCamera
      }) {
        do {
          try virtual.lockForConfiguration()
          virtual.videoZoomFactor = max(virtual.minAvailableVideoZoomFactor, 0.5)
          virtual.unlockForConfiguration()
        } catch {}
        return virtual
      }
      if let ultra = discovery.devices.first(where: { device in
        device.deviceType == .builtInUltraWideCamera
      }) {
        return ultra
      }
      throw CameraNativeError.lensUnavailable
    }

    if let virtual = discovery.devices.first(where: { device in
      device.deviceType == .builtInTripleCamera
        || device.deviceType == .builtInDualWideCamera
    }) {
      do {
        try virtual.lockForConfiguration()
        virtual.videoZoomFactor = 1.0
        virtual.unlockForConfiguration()
      } catch {}
      return virtual
    }
    if let wide = discovery.devices.first(where: { device in
      device.deviceType == .builtInWideAngleCamera
    }) {
      return wide
    }
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
