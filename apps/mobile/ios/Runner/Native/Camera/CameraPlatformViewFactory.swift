import Flutter
import UIKit

final class CameraPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let hostApi: CameraHostApiImpl

  init(hostApi: CameraHostApiImpl) {
    self.hostApi = hostApi
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return CameraPlatformView(frame: frame, session: hostApi.cameraManager.session)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
