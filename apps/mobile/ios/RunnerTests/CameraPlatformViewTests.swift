@preconcurrency import AVFoundation
@testable import Runner
import XCTest

final class CameraPlatformViewTests: XCTestCase {
  func testShowFocusRingAddsShapeSublayer() {
    let view = CameraPreviewContainerView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let initialSublayers = view.layer.sublayers?.count ?? 0
    view.showFocusRing(at: CGPoint(x: 200, y: 400))
    let after = view.layer.sublayers?.count ?? 0
    XCTAssertEqual(after, initialSublayers + 1)
    let ring = view.layer.sublayers?.last as? CAShapeLayer
    XCTAssertNotNil(ring)
    XCTAssertEqual(ring?.strokeColor, UIColor.white.cgColor)
    XCTAssertEqual(ring?.lineWidth, FocusRingConfig.strokeWidth)
    XCTAssertTrue(ring?.path != nil)
  }

  func testShowFocusRingAnimationsConfigured() {
    let view = CameraPreviewContainerView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    view.showFocusRing(at: CGPoint(x: 100, y: 100))
    let ring = view.layer.sublayers?.last as? CAShapeLayer
    let scale = ring?.animation(forKey: "scale") as? CABasicAnimation
    XCTAssertEqual(scale?.fromValue as? CGFloat, FocusRingConfig.scaleFrom)
    XCTAssertEqual(scale?.toValue as? CGFloat, FocusRingConfig.scaleTo)
    XCTAssertEqual(scale?.duration, FocusRingConfig.duration)
    let opacity = ring?.animation(forKey: "opacity") as? CAKeyframeAnimation
    XCTAssertEqual(opacity?.values as? [NSNumber], FocusRingConfig.opacityKeyframes)
    XCTAssertEqual(opacity?.keyTimes, FocusRingConfig.opacityKeyTimes)
  }
}
