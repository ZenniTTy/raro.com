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

  func testStartIsIdempotent() {
    let coordinator = AudioSessionCoordinator()
    let first = coordinator.start()
    let second = coordinator.start()
    XCTAssertEqual(first, second)
    coordinator.stop()
  }

  func testStopIsIdempotent() {
    let coordinator = AudioSessionCoordinator()
    coordinator.stop()
    coordinator.stop()
  }

  func testStartThenStopDoesNotEmitFrames() {
    let coordinator = AudioSessionCoordinator()
    let unexpected = XCTestExpectation(description: "no frame after start then stop")
    unexpected.isInverted = true
    var frameCount = 0
    coordinator.onFrame = { _ in
      frameCount += 1
      unexpected.fulfill()
    }
    _ = coordinator.start()
    coordinator.stop()
    wait(for: [unexpected], timeout: 0.3)
    XCTAssertEqual(frameCount, 0)
  }
}
