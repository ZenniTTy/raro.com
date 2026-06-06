import Flutter
import Foundation

final class ReplayBufferHostApiImpl: NSObject, ReplayBufferHostApi, @unchecked Sendable {
  private let manager: CameraManager
  private let flutterApi: ReplayBufferFlutterApi

  init(manager: CameraManager, messenger: FlutterBinaryMessenger) {
    self.manager = manager
    self.flutterApi = ReplayBufferFlutterApi(binaryMessenger: messenger)
    super.init()
    manager.onReplaySaved = { [weak self] url, durationMs in
      DispatchQueue.main.async {
        self?.flutterApi.onReplaySaved(path: url.path, durationMs: Int64(durationMs)) { _ in }
      }
    }
    manager.onReplayFailed = { [weak self] error in
      DispatchQueue.main.async {
        self?.flutterApi.onReplayFailed(code: error.code, message: error.message) { _ in }
      }
    }
  }

  func enableReplayBuffer(seconds: Int64) throws {
    manager.setReplayWindow(seconds: Int(seconds))
  }

  func disableReplayBuffer() throws {
    manager.setReplayWindow(seconds: 0)
  }

  func saveReplay() throws {
    do {
      try manager.saveReplay()
    } catch let error as CameraNativeError {
      throw ReplayBufferPigeonError(code: "\(error.code)", message: error.message, details: nil)
    } catch {
      throw ReplayBufferPigeonError(code: "sessionFailed", message: error.localizedDescription, details: nil)
    }
  }
}
