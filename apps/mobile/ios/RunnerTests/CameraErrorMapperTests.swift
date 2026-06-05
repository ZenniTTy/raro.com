import XCTest
@testable import Runner

final class CameraErrorMapperTests: XCTestCase {
  func testSessionInterruptedMapsToInterruptedCode() {
    XCTAssertEqual(CameraNativeError.sessionInterrupted.code, .sessionInterrupted)
  }

  func testSessionFailedMapsToFailedCodeAndCarriesMessage() {
    let error = CameraNativeError.sessionFailed("boom")
    XCTAssertEqual(error.code, .sessionFailed)
    XCTAssertEqual(error.message, "boom")
  }

  func testInterruptedCarriesNoMessage() {
    XCTAssertNil(CameraNativeError.sessionInterrupted.message)
  }

  func testFormatUnsupportedMapsToFormatCode() {
    XCTAssertEqual(CameraNativeError.formatUnsupported.code, .formatUnsupported)
  }
}
