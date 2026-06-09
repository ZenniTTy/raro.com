import XCTest
@preconcurrency import AVFoundation
@testable import Runner

final class AudioSessionCoordinatorTests: XCTestCase {
  func testStopDoesNotEmitFramesAfterStop() {
    let coordinator = AudioSessionCoordinator()
    let unexpected = XCTestExpectation(description: "no frame after stop")
    unexpected.isInverted = true
    var frameCount = 0
    coordinator.onFrame = { _ in
      frameCount += 1
      unexpected.fulfill()
    }
    coordinator.stop()
    wait(for: [unexpected], timeout: 0.3)
    XCTAssertEqual(frameCount, 0)
  }

  func testTargetFormatIs16kMono() {
    let coordinator = AudioSessionCoordinator()
    XCTAssertEqual(coordinator.targetSampleRate, 16000)
    XCTAssertEqual(coordinator.targetChannels, 1)
  }
}
