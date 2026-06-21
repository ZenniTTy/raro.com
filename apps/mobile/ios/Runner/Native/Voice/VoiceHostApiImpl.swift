import Foundation

final class VoiceHostApiImpl: NSObject, VoiceHostApi {
  let manager: VoiceManager
  private let flutterApi: VoiceFlutterApi

  init(manager: VoiceManager, flutterApi: VoiceFlutterApi) {
    self.manager = manager
    self.flutterApi = flutterApi
    super.init()
    manager.onCommand = { [weak self] cmd in
      self?.flutterApi.onWakeDetected(command: cmd == .start ? .start : .stop) { _ in }
    }
    manager.onStateChanged = { [weak self] state in
      self?.flutterApi.onListeningStateChanged(state: state) { _ in }
    }
  }

  func isAvailable(completion: @escaping (Result<Bool, Error>) -> Void) {
    manager.isAvailable { ok in completion(.success(ok)) }
  }

  func startListening() throws { manager.start() }
  func stopListening() throws { manager.stop() }
}
