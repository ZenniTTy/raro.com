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
    if let existing = session {
      os_log("startSession called while session exists — stopping previous", log: cameraLog, type: .default)
      existing.stopRunning()
      session = nil
      device = nil
      input = nil
    }
    guard hasPermission() else { throw CameraNativeError.permissionDenied }

    let device = try selectDevice(for: config.lens)
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
    do {
      try newDevice.lockForConfiguration()
      newDevice.videoZoomFactor = newDevice.minAvailableVideoZoomFactor
      newDevice.unlockForConfiguration()
    } catch {
      os_log("zoom reset failed (non-fatal): %{public}@", log: cameraLog, type: .info, error.localizedDescription)
    }
    session.commitConfiguration()
    self.device = newDevice
    self.input = newInput
    onLensSwitched?(lens)
  }

  func setFormat(resolution: Resolution, fps: Fps) throws {
    guard let device = device else { throw CameraNativeError.notRunning }
    guard let session = session else { throw CameraNativeError.notRunning }
    session.beginConfiguration()
    session.sessionPreset = .inputPriority
    try device.lockForConfiguration()
    try applyFormat(device: device, resolution: resolution, fps: fps)
    let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    device.unlockForConfiguration()
    session.commitConfiguration()
    os_log(
      "setFormat %{public}@@%{public}@ -> %dx%d",
      log: cameraLog, type: .info,
      "\(resolution)", "\(fps)", Int(dims.width), Int(dims.height)
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
        .builtInUltraWideCamera, .builtInWideAngleCamera,
        .builtInDualWideCamera, .builtInTripleCamera,
      ],
      mediaType: .video,
      position: .back
    )

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

    let chosen: AVCaptureDevice.Format
    if let match = exactMatches.first {
      chosen = match
    } else {
      let withFps = device.formats.filter { format in
        format.videoSupportedFrameRateRanges.contains { range in
          range.minFrameRate <= targetFps && range.maxFrameRate >= targetFps
        }
      }
      let candidates = withFps.isEmpty ? device.formats : withFps
      guard
        let best = candidates.min(by: { a, b in
          let da = CMVideoFormatDescriptionGetDimensions(a.formatDescription)
          let db = CMVideoFormatDescriptionGetDimensions(b.formatDescription)
          return abs(Int(da.width) - Int(targetWidth)) < abs(Int(db.width) - Int(targetWidth))
        })
      else { throw CameraNativeError.formatUnsupported }
      chosen = best
      let dims = CMVideoFormatDescriptionGetDimensions(best.formatDescription)
      os_log(
        "applyFormat fallback target=%dx%d@%.0f chose=%dx%d",
        log: cameraLog, type: .info,
        Int(targetWidth), Int(targetHeight), targetFps,
        Int(dims.width), Int(dims.height)
      )
    }
    device.activeFormat = chosen
    let duration = CMTime(value: 1, timescale: Int32(targetFps))
    device.activeVideoMinFrameDuration = duration
    device.activeVideoMaxFrameDuration = duration
  }
}
