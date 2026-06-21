import XCTest
@testable import Runner

final class WakeWordDetectorTests: XCTestCase {
  func testDetectorConstructsWithBundledModels() {
    XCTAssertNoThrow(try WakeWordDetector())
  }

  func testFeedingSilenceDoesNotCrashAndDoesNotFalseFire() throws {
    let detector = try WakeWordDetector()
    var wakes = 0
    detector.onWake = { wakes += 1 }
    detector.process([Float](repeating: 0, count: 16000 * 2))
    XCTAssertEqual(wakes, 0, "pure silence must not trigger a wake")
  }
}
