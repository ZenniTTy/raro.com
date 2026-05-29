@preconcurrency import AVFoundation
@testable import Runner
import XCTest

final class CameraManagerFocusTests: XCTestCase {
  func testStopSessionCancelsPendingFocusCallbacks() {
    let manager = CameraManager()
    var resultCount = 0
    let unexpected = XCTestExpectation(description: "no callback fires after stopSession")
    unexpected.isInverted = true
    manager.onFocusResult = { _, _ in
      resultCount += 1
      unexpected.fulfill()
    }
    manager.stopSession()
    wait(for: [unexpected], timeout: 0.3)
    XCTAssertEqual(resultCount, 0, "stopSession must cancel pending focus pipeline")
  }

  func testFocusResultCallbackTypeAcceptsPointAndBool() {
    let manager = CameraManager()
    var captured: (FocusPoint, Bool)?
    manager.onFocusResult = { point, success in
      captured = (point, success)
    }
    let testPoint = FocusPoint(x: 0.4, y: 0.6)
    manager.onFocusResult?(testPoint, true)
    let unwrapped = try? XCTUnwrap(captured)
    XCTAssertEqual(unwrapped?.0.x ?? 0, 0.4, accuracy: 0.0001)
    XCTAssertEqual(unwrapped?.0.y ?? 0, 0.6, accuracy: 0.0001)
    XCTAssertEqual(unwrapped?.1, true)
  }
}
