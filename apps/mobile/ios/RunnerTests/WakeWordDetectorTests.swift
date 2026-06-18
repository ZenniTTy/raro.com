import XCTest
@testable import Runner

final class WakeWordDetectorTests: XCTestCase {
  func testDetectorConstructsWithBundledModels() {
    XCTAssertNoThrow(try WakeWordDetector())
  }

  func testFeedingSilenceDoesNotCrashAndDoesNotFalseFire() throws {
    let detector = try WakeWordDetector()
    var commands: [WakeCommand] = []
    detector.onCommand = { commands.append($0) }
    detector.process([Float](repeating: 0, count: 16000 * 2))
    XCTAssertTrue(commands.isEmpty, "pure silence must not trigger a wake command")
  }
}
