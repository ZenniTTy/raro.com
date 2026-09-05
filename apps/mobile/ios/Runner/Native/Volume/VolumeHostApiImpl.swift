import AVKit
import UIKit

final class VolumeHostApiImpl: NSObject, VolumeHostApi {
  private let flutterApi: VolumeFlutterApi
  private var interaction: AnyObject?
  private var listening = false

  init(flutterApi: VolumeFlutterApi) {
    self.flutterApi = flutterApi
    super.init()
  }

  func isAvailable(completion: @escaping (Result<Bool, Error>) -> Void) {
    if #available(iOS 17.2, *) {
      completion(.success(true))
    } else {
      completion(.success(false))
    }
  }

  func startListening() throws {
    setListening(true)
  }

  func stopListening() throws {
    setListening(false)
  }

  private func setListening(_ enabled: Bool) {
    listening = enabled
    guard #available(iOS 17.2, *) else { return }
    if enabled { ensureInteraction() }
    (interaction as? AVCaptureEventInteraction)?.isEnabled = enabled
  }

  @available(iOS 17.2, *)
  private func ensureInteraction() {
    guard interaction == nil, let view = hostView() else { return }
    let eventInteraction = AVCaptureEventInteraction(
      primary: { [weak self] event in
        guard event.phase == .ended else { return }
        self?.emit(.down)
      },
      secondary: { [weak self] event in
        guard event.phase == .ended else { return }
        self?.emit(.up)
      },
    )
    eventInteraction.isEnabled = false
    view.addInteraction(eventInteraction)
    interaction = eventInteraction
  }

  private func emit(_ direction: VolumeDirection) {
    guard listening else { return }
    flutterApi.onVolumePressed(direction: direction) { _ in }
  }

  private func hostView() -> UIView? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController?.view
  }
}
