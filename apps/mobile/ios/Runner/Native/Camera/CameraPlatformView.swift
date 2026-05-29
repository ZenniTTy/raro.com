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

  func showFocusRing(at point: CGPoint) {
    let ring = CAShapeLayer()
    let radius = FocusRingConfig.radius
    let bounds = CGRect(
      x: point.x - radius,
      y: point.y - radius,
      width: radius * 2,
      height: radius * 2
    )
    ring.path = UIBezierPath(ovalIn: bounds).cgPath
    ring.strokeColor = FocusRingConfig.color.cgColor
    ring.fillColor = UIColor.clear.cgColor
    ring.lineWidth = FocusRingConfig.strokeWidth
    ring.contentsScale = UIScreen.main.scale
    ring.opacity = 0

    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = FocusRingConfig.scaleFrom
    scale.toValue = FocusRingConfig.scaleTo
    scale.duration = FocusRingConfig.duration
    scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

    let opacity = CAKeyframeAnimation(keyPath: "opacity")
    opacity.values = FocusRingConfig.opacityKeyframes
    opacity.keyTimes = FocusRingConfig.opacityKeyTimes
    opacity.duration = FocusRingConfig.duration

    ring.add(scale, forKey: "scale")
    ring.add(opacity, forKey: "opacity")

    layer.addSublayer(ring)
    DispatchQueue.main.asyncAfter(deadline: .now() + FocusRingConfig.duration) { [weak ring] in
      ring?.removeFromSuperlayer()
    }
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

  func showFocusRing(at point: CGPoint) {
    container.showFocusRing(at: point)
  }
}
