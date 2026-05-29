import AVFoundation
import Flutter
import Foundation
import os.log

private let focusLog = OSLog(subsystem: "com.rarocamera", category: "focus")

final class CameraHostApiImpl: NSObject, CameraHostApi, @unchecked Sendable {
  private let manager = CameraManager()
  private let flutterApi: CameraFlutterApi
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
    DispatchQueue.main.async {
      let sensorPoint = self.convertNormalizedToSensor(point) ?? CGPoint(x: point.x, y: point.y)
      let t1 = CFAbsoluteTimeGetCurrent()
      os_log(
        "focusAt input=(%.3f,%.3f) sensor=(%.3f,%.3f) convertMs=%.1f",
        log: focusLog, type: .info,
        point.x, point.y, sensorPoint.x, sensorPoint.y, (t1 - t0) * 1000
      )
      do {
        try self.manager.focusAt(sensorPoint: sensorPoint, normalizedPoint: point)
        let t2 = CFAbsoluteTimeGetCurrent()
        guard let factory = self.platformViewFactory else {
          os_log("focusAt no factory totalMs=%.1f", log: focusLog, type: .info, (t2 - t0) * 1000)
          completion(.success(()))
          return
        }
        factory.lastPlatformView?.showFocusRing(
          at: factory.toViewCoordinates(focusPoint: point)
        )
        let t3 = CFAbsoluteTimeGetCurrent()
        os_log(
          "focusAt ring rendered totalMs=%.1f focusMs=%.1f ringMs=%.1f",
          log: focusLog, type: .info,
          (t3 - t0) * 1000, (t2 - t1) * 1000, (t3 - t2) * 1000
        )
        completion(.success(()))
      } catch let error as CameraNativeError {
        completion(.failure(self.pigeonError(from: error)))
      } catch {
        completion(.failure(self.pigeonError(code: .sessionFailed, message: error.localizedDescription)))
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

  private func pigeonError(from error: CameraNativeError) -> PigeonError {
    return pigeonError(code: error.code, message: error.message)
  }

  private func pigeonError(code: CameraErrorCode, message: String?) -> PigeonError {
    return PigeonError(code: "\(code)", message: message, details: nil)
  }
}
