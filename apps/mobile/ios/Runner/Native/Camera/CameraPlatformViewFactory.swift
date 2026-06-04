import Flutter
import os.log
import UIKit

private let factoryLog = OSLog(subsystem: "com.rarocamera", category: "camera")

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
    let session = hostApi.cameraManager.session
    os_log(
      "platformView create session=%{public}@ running=%{public}@",
      log: factoryLog, type: .debug,
      session == nil ? "nil" : "present",
      "\(session?.isRunning ?? false)"
    )
    let view = CameraPlatformView(
      frame: frame,
      session: session,
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
