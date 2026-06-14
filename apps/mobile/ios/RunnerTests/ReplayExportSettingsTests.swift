import AVFoundation
import XCTest

@testable import Runner

final class ReplayExportSettingsTests: XCTestCase {
  func testReplayVideoSettingsForcesKeyframePerChunk() throws {
    let props = RecordingPipeline.injectKeyframeInterval(
      into: [AVVideoCodecKey: AVVideoCodecType.hevc],
      chunkSeconds: 1,
      fps: 60
    )
    let compression = props[AVVideoCompressionPropertiesKey] as? [String: Any]
    XCTAssertNotNil(compression, "compression properties must exist")
    let maxKeyFrameDuration =
      compression?[AVVideoMaxKeyFrameIntervalDurationKey as String] as? Double
    XCTAssertEqual(maxKeyFrameDuration, 1.0, "must force ≥1 IDR per 1s chunk (duration)")
    let maxKeyFrameCount =
      compression?[AVVideoMaxKeyFrameIntervalKey as String] as? Int
    XCTAssertEqual(
      maxKeyFrameCount, 60, "must force ≥1 IDR per 1s chunk (frame count = fps*chunkSeconds)")
  }
}
