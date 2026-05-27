import AVFoundation
import Flutter
import UIKit

final class CameraPlatformView: NSObject, FlutterPlatformView {
  private let container = UIView()
  private let previewLayer: AVCaptureVideoPreviewLayer

  init(frame: CGRect, session: AVCaptureSession?) {
    if let session = session {
      previewLayer = AVCaptureVideoPreviewLayer(session: session)
    } else {
      previewLayer = AVCaptureVideoPreviewLayer()
    }
    super.init()
    container.frame = frame
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = container.bounds
    container.layer.addSublayer(previewLayer)
  }

  func view() -> UIView { container }

  func updateSession(_ session: AVCaptureSession) {
    previewLayer.session = session
    previewLayer.frame = container.bounds
  }
}
