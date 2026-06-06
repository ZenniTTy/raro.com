import AVFoundation
import Flutter
import Foundation
import os.log

private let focusLog = OSLog(subsystem: "com.rarocamera", category: "focus")

final class CameraHostApiImpl: NSObject, CameraHostApi, @unchecked Sendable {
  private let manager = CameraManager()
  private let flutterApi: CameraFlutterApi
  private let thumbnailGenerator = ThumbnailGenerator()
  weak var platformViewFactory: CameraPlatformViewFactory?

  init(messenger: FlutterBinaryMessenger) {
    self.flutterApi = CameraFlutterApi(binaryMessenger: messenger)
    super.init()
    manager.onLensSwitched = { [weak self] lens in
      DispatchQueue.main.async {
        self?.flutterApi.onLensSwitched(lens: lens) { _ in }
      }
    }
    manager.onError = { [weak self] error in
      DispatchQueue.main.async {
        self?.flutterApi.onError(code: error.code, message: error.message) { _ in }
      }
    }
    manager.onFocusResult = { [weak self] point, success in
      DispatchQueue.main.async {
        self?.flutterApi.onFocusChanged(point: point, locked: success) { _ in }
      }
    }
    manager.onRecordingFinished = { [weak self] url, durationMs in
      DispatchQueue.main.async {
        self?.flutterApi.onRecordingFinished(path: url.path, durationMs: Int64(durationMs)) { _ in }
      }
    }
    manager.onRecordingFailed = { [weak self] message in
      DispatchQueue.main.async {
        self?.flutterApi.onRecordingFailed(code: .sessionFailed, message: message) { _ in }
      }
    }
  }

  var cameraManager: CameraManager { manager }

  func discoverCapabilities(completion: @escaping (Result<CameraCapabilities, Error>) -> Void) {
    do {
      let caps = try manager.discoverCapabilities()
      completion(.success(caps))
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .sessionFailed, message: error.localizedDescription)))
    }
  }

  func startSession(
    textureId: Int64,
    config: CameraConfig,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    Task {
      do {
        try await manager.startSession(config: config)
        DispatchQueue.main.async {
          self.flutterApi.onSessionStarted(activeConfig: config) { _ in }
          completion(.success(()))
        }
      } catch let error as CameraNativeError {
        DispatchQueue.main.async {
          completion(.failure(self.pigeonError(from: error)))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(self.pigeonError(code: .sessionFailed, message: error.localizedDescription)))
        }
      }
    }
  }

  func stopSession(completion: @escaping (Result<Void, Error>) -> Void) {
    manager.stopSession()
    flutterApi.onSessionStopped { _ in }
    completion(.success(()))
  }

  func startRecording(options: RecordingOptions) throws -> String {
    let sessionId = UUID().uuidString
    do {
      try manager.startRecording(sessionId: sessionId, codec: options.codec)
      return sessionId
    } catch let error as CameraNativeError {
      throw pigeonError(from: error)
    } catch {
      throw pigeonError(code: .sessionFailed, message: error.localizedDescription)
    }
  }

  func stopRecording() throws {
    do {
      try manager.stopRecording()
    } catch let error as CameraNativeError {
      throw pigeonError(from: error)
    } catch {
      throw pigeonError(code: .sessionFailed, message: error.localizedDescription)
    }
  }

  func generateThumbnail(
    videoPath: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    thumbnailGenerator.generate(videoPath: videoPath) { [weak self] result in
      switch result {
      case let .success(path):
        completion(.success(path))
      case let .failure(error):
        completion(.failure(
          self?.pigeonError(code: .formatUnsupported, message: error.localizedDescription)
            ?? error
        ))
      }
    }
  }

  func switchLens(lens: LensType, completion: @escaping (Result<Void, Error>) -> Void) {
    do {
      try manager.switchLens(lens)
      completion(.success(()))
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .sessionFailed, message: error.localizedDescription)))
    }
  }

  func setFormat(
    resolution: Resolution,
    fps: Fps,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    do {
      try manager.setFormat(resolution: resolution, fps: fps)
      completion(.success(()))
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .formatUnsupported, message: error.localizedDescription)))
    }
  }

  func focusAt(point: FocusPoint, completion: @escaping (Result<Void, Error>) -> Void) {
    let t0 = CFAbsoluteTimeGetCurrent()
    let renderRing: () -> Void = { [weak self] in
      guard let self = self, let factory = self.platformViewFactory else { return }
      factory.lastPlatformView?.showFocusRing(
        at: factory.toViewCoordinates(focusPoint: point)
      )
    }
    let runOnMain: (@escaping () -> Void) -> Void = { block in
      if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }
    runOnMain {
      renderRing()
      let tRing = CFAbsoluteTimeGetCurrent()
      os_log(
        "focusAt ring rendered ringMs=%.1f input=(%.3f,%.3f)",
        log: focusLog, type: .info,
        (tRing - t0) * 1000, point.x, point.y
      )
      let sensorPoint = self.convertNormalizedToSensor(point) ?? CGPoint(x: point.x, y: point.y)
      let tConvert = CFAbsoluteTimeGetCurrent()
      completion(.success(()))
      self.manager.focusAtAsync(sensorPoint: sensorPoint, normalizedPoint: point) { focusErr in
        let tFocus = CFAbsoluteTimeGetCurrent()
        os_log(
          "focusAt focus applied totalMs=%.1f convertMs=%.1f focusMs=%.1f sensor=(%.3f,%.3f) err=%{public}@",
          log: focusLog, type: .info,
          (tFocus - t0) * 1000, (tConvert - tRing) * 1000, (tFocus - tConvert) * 1000,
          sensorPoint.x, sensorPoint.y,
          focusErr.map { "\($0)" } ?? "nil"
        )
      }
    }
  }

  private func convertNormalizedToSensor(_ point: FocusPoint) -> CGPoint? {
    guard let container = platformViewFactory?.lastPlatformView?.view() as? CameraPreviewContainerView else {
      return nil
    }
    let bounds = container.bounds
    guard bounds.width > 0, bounds.height > 0 else { return nil }
    let layerPoint = CGPoint(
      x: CGFloat(point.x) * bounds.width,
      y: CGFloat(point.y) * bounds.height
    )
    return container.previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
  }

  func requestPermission(completion: @escaping (Result<Bool, Error>) -> Void) {
    Task {
      let granted = await manager.requestPermission()
      DispatchQueue.main.async {
        completion(.success(granted))
      }
    }
  }

  func hasPermission(completion: @escaping (Result<Bool, Error>) -> Void) {
    completion(.success(manager.hasPermission()))
  }

  private func pigeonError(from error: CameraNativeError) -> CameraPigeonError {
    return pigeonError(code: error.code, message: error.message)
  }

  private func pigeonError(code: CameraErrorCode, message: String?) -> CameraPigeonError {
    return CameraPigeonError(code: "\(code)", message: message, details: nil)
  }
}
