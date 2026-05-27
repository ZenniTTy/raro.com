import Flutter
import Foundation

final class CameraHostApiImpl: NSObject, CameraHostApi {
  private let manager = CameraManager()
  private let flutterApi: CameraFlutterApi

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
    do {
      try manager.focusAt(point: point)
      flutterApi.onFocusChanged(point: point, locked: true) { _ in }
      completion(.success(()))
    } catch let error as CameraNativeError {
      completion(.failure(pigeonError(from: error)))
    } catch {
      completion(.failure(pigeonError(code: .sessionFailed, message: error.localizedDescription)))
    }
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
    return PigeonError(code: String(code.rawValue), message: message, details: nil)
  }
}
