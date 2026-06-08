import XCTest
@testable import Runner

final class VoiceManagerTests: XCTestCase {
  func testParserMatchesGravarStart() {
    XCTAssertEqual(VoiceCommandParser.parse("raro gravar", wakeWord: "Raro"), .start)
    XCTAssertEqual(VoiceCommandParser.parse("Raro, começar a gravar", wakeWord: "Raro"), .start)
  }

  func testParserMatchesPararStop() {
    XCTAssertEqual(VoiceCommandParser.parse("raro parar", wakeWord: "Raro"), .stop)
  }

  func testParserIgnoresNonCommand() {
    XCTAssertNil(VoiceCommandParser.parse("que dia raro hoje", wakeWord: "Raro"))
    XCTAssertNil(VoiceCommandParser.parse("gravar sem wake", wakeWord: "Raro"))
  }
}
