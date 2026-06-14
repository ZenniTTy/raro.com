import AVFoundation
import XCTest
@testable import Runner

final class CameraManagerRecordingTests: XCTestCase {
  func testCodecSelectionPrefersHevcWhenAvailable() {
    let chosen = RecordingPipeline.selectCodec(
      requested: "h265",
      available: [.hevc, .h264]
    )
    XCTAssertEqual(chosen, .hevc)
  }

  func testCodecSelectionFallsBackToH264WhenHevcMissing() {
    let chosen = RecordingPipeline.selectCodec(
      requested: "h265",
      available: [.h264]
    )
    XCTAssertEqual(chosen, .h264)
  }

  func testCodecSelectionHonorsExplicitH264() {
    let chosen = RecordingPipeline.selectCodec(
      requested: "h264",
      available: [.hevc, .h264]
    )
    XCTAssertEqual(chosen, .h264)
  }

  func testOutputUrlUsesMp4ExtensionInVaultDir() {
    let url = RecordingPipeline.makeOutputURL(sessionId: "abc123")
    XCTAssertEqual(url.pathExtension, "mp4")
    XCTAssertTrue(url.lastPathComponent.contains("abc123"))
  }

  func testNewPipelineIsNotRecording() {
    let pipeline = RecordingPipeline()
    XCTAssertFalse(pipeline.isRecording)
  }
}
