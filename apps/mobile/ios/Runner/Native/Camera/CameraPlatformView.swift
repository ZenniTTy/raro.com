import AVFoundation
import Flutter
import UIKit

final class CameraPreviewContainerView: UIView {
  override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

  weak var cameraManager: CameraManager?

  var previewLayer: AVCaptureVideoPreviewLayer {
    return layer as! AVCaptureVideoPreviewLayer
  }

  var session: AVCaptureSession? {
    get { previewLayer.session }
    set { previewLayer.session = newValue }
  }

  func installTapToFocus() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    tap.delaysTouchesBegan = false
    tap.delaysTouchesEnded = false
    addGestureRecognizer(tap)
  }

  @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    let tapPoint = recognizer.location(in: self)
    showFocusRing(at: tapPoint)

    let viewBounds = bounds
    guard viewBounds.width > 0, viewBounds.height > 0 else { return }
    let normalized = FocusPoint(
      x: Double(min(max(tapPoint.x / viewBounds.width, 0), 1)),
      y: Double(min(max(tapPoint.y / viewBounds.height, 0), 1))
    )
    let sensorPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
    cameraManager?.focusAtAsync(sensorPoint: sensorPoint, normalizedPoint: normalized) { _ in }
  }

  func showFocusRing(at point: CGPoint) {
    let ring = CAShapeLayer()
    let radius = FocusRingConfig.radius
    let diameter = radius * 2
    ring.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
    ring.position = point
    ring.path = UIBezierPath(
      ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter)
    ).cgPath
    ring.strokeColor = FocusRingConfig.color.cgColor
    ring.fillColor = UIColor.clear.cgColor
    ring.lineWidth = FocusRingConfig.strokeWidth
    ring.contentsScale = UIScreen.main.scale
    ring.opacity = 1

    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = FocusRingConfig.scaleFrom
    scale.toValue = FocusRingConfig.scaleTo
    scale.duration = FocusRingConfig.duration
    scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

    let opacity = CAKeyframeAnimation(keyPath: "opacity")
    opacity.values = FocusRingConfig.opacityKeyframes
    opacity.keyTimes = FocusRingConfig.opacityKeyTimes
    opacity.duration = FocusRingConfig.duration
    opacity.fillMode = .forwards
    opacity.isRemovedOnCompletion = false

    ring.add(scale, forKey: "scale")
    ring.add(opacity, forKey: "opacity")

    layer.addSublayer(ring)
    ring.setNeedsDisplay()

    DispatchQueue.main.asyncAfter(deadline: .now() + FocusRingConfig.duration) { [weak ring] in
      ring?.removeFromSuperlayer()
    }
  }
}

final class CameraPlatformView: NSObject, FlutterPlatformView {
  private let container: CameraPreviewContainerView

  init(frame: CGRect, session: AVCaptureSession?, manager: CameraManager?) {
    container = CameraPreviewContainerView(frame: frame)
    super.init()
    container.backgroundColor = .black
    container.previewLayer.videoGravity = .resizeAspectFill
    container.session = session
    container.cameraManager = manager
    container.installTapToFocus()
  }

  func view() -> UIView { container }

  func showFocusRing(at point: CGPoint) {
    container.showFocusRing(at: point)
  }
}
