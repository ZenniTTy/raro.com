import XCTest
import AVFoundation
import os.log
@testable import Runner

final class WakeWordRecallTests: XCTestCase {
  private let recallLog = OSLog(subsystem: "com.rarocamera/voice", category: "recall")
  private static let silenceSamples = 24000

  private let raroFixtures = [
    "raro_1", "raro_2", "raro_3", "raro_4", "raro_5", "raro_6",
  ]

  private func loadSamples(_ name: String) throws -> [Float] {
    let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "wav")
    XCTAssertNotNil(url, "fixture \(name).wav not found in test bundle — resource wiring is wrong")
    guard let url = url else { return [] }

    let file = try AVAudioFile(forReading: url)
    guard let targetFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: 16000,
      channels: 1,
      interleaved: false
    ) else {
      XCTFail("could not build target format for \(name)")
      return []
    }

    guard let converter = AVAudioConverter(from: file.processingFormat, to: targetFormat) else {
      XCTFail("could not build converter for \(name)")
      return []
    }

    let frameCount = AVAudioFrameCount(file.length)
    guard let inputBuffer = AVAudioPCMBuffer(
      pcmFormat: file.processingFormat,
      frameCapacity: frameCount
    ) else {
      XCTFail("could not allocate input buffer for \(name)")
      return []
    }
    try file.read(into: inputBuffer)

    let ratio = targetFormat.sampleRate / file.processingFormat.sampleRate
    let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1024
    guard let outputBuffer = AVAudioPCMBuffer(
      pcmFormat: targetFormat,
      frameCapacity: outputCapacity
    ) else {
      XCTFail("could not allocate output buffer for \(name)")
      return []
    }

    var consumed = false
    var error: NSError?
    converter.convert(to: outputBuffer, error: &error) { _, status in
      if consumed {
        status.pointee = .endOfStream
        return nil
      }
      consumed = true
      status.pointee = .haveData
      return inputBuffer
    }
    if let error = error {
      XCTFail("convert error for \(name): \(error.localizedDescription)")
      return []
    }

    guard let channel = outputBuffer.floatChannelData?[0] else {
      XCTFail("no float channel data for \(name)")
      return []
    }
    return Array(UnsafeBufferPointer(start: channel, count: Int(outputBuffer.frameLength)))
  }

  private func padded(_ samples: [Float]) -> [Float] {
    let silence = [Float](repeating: 0, count: Self.silenceSamples)
    return silence + samples + silence
  }

  private func fires(for name: String) throws -> Bool {
    let detector = try WakeWordDetector()
    var fired = false
    detector.onWake = { fired = true }
    let samples = try loadSamples(name)
    detector.process(padded(samples))
    return fired
  }

  private func maxScore(for name: String, provider: OnnxExecutionProvider) throws -> Float {
    let detector = try WakeWordDetector(classifierProvider: provider)
    var maxScore: Float = 0
    detector.onScoreForTesting = { s in
      if s > maxScore { maxScore = s }
    }
    let samples = try loadSamples(name)
    detector.process(padded(samples))
    return maxScore
  }

  func testRawScoresCoreMLvsCPU() throws {
    for provider in [OnnxExecutionProvider.coreML, OnnxExecutionProvider.cpu] {
      let tag = provider == .coreML ? "CoreML" : "CPU"
      var lines: [String] = []
      for name in raroFixtures {
        let s = try maxScore(for: name, provider: provider)
        lines.append(String(format: "%@ raro=%.3f", name, s))
      }
      let summary = "SCORES[\(tag)]: " + lines.joined(separator: " | ")
      os_log("%{public}@", log: recallLog, type: .default, summary)
      print(summary)
    }
  }

  func testRaroClipsFireWake() throws {
    var hits = 0
    var results: [String] = []
    for name in raroFixtures {
      let fired = try fires(for: name)
      if fired {
        hits += 1
        results.append("\(name)=wake")
      } else {
        results.append("\(name)=none")
      }
    }
    let total = raroFixtures.count
    os_log("RECALL RESULT: raro %d/%d fired .wake — %{public}@",
           log: recallLog, type: .default, hits, total, results.joined(separator: " "))
    print("RECALL RESULT: raro \(hits)/\(total) fired .wake — \(results.joined(separator: " "))")

    for name in raroFixtures {
      XCTAssertTrue(try fires(for: name), "\(name) (contains 'raro') should fire .wake")
    }
  }
}
