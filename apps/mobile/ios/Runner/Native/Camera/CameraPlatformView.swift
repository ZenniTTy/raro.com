import AVFoundation
import Flutter
import UIKit

final class CameraPreviewContainerView: UIView {
  override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

  var previewLayer: AVCaptureVideoPreviewLayer {
    return layer as! AVCaptureVideoPreviewLayer
  }

  var session: AVCaptureSession? {
    get { previewLayer.session }
    set { previewLayer.session = newValue }
  }
}

final class CameraPlatformView: NSObject, FlutterPlatformView {
  private let container: CameraPreviewContainerView

  init(frame: CGRect, session: AVCaptureSession?) {
    container = CameraPreviewContainerView(frame: frame)
    super.init()
    container.backgroundColor = .black
    container.previewLayer.videoGravity = .resizeAspectFill
    container.session = session
  }

  func view() -> UIView { container }
}
