import Flutter
import UIKit

final class CameraPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let hostApi: CameraHostApiImpl
  weak var lastPlatformView: CameraPlatformView?

  init(hostApi: CameraHostApiImpl) {
    self.hostApi = hostApi
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let view = CameraPlatformView(
      frame: frame,
      session: hostApi.cameraManager.session,
      manager: hostApi.cameraManager
    )
    lastPlatformView = view
    return view
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func toViewCoordinates(focusPoint: FocusPoint) -> CGPoint {
    guard let view = lastPlatformView?.view() else {
      return CGPoint(x: focusPoint.x, y: focusPoint.y)
    }
    return CGPoint(
      x: CGFloat(focusPoint.x) * view.bounds.width,
      y: CGFloat(focusPoint.y) * view.bounds.height
    )
  }
}
