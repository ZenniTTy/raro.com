import XCTest
import AVFoundation
import os.log
@testable import Runner

final class WakeWordRecallTests: XCTestCase {
  private let recallLog = OSLog(subsystem: "com.rarocamera/voice", category: "recall")
  private static let silenceSamples = 24000

  private let gravarFixtures = ["gravar_1", "gravar_2", "gravar_3", "gravar_4"]
  private let pararFixtures = ["parar_1", "parar_2", "parar_3", "parar_4"]

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

  private func fireCommand(for name: String) throws -> WakeCommand? {
    let detector = try WakeWordDetector()
    var captured: WakeCommand?
    detector.onCommand = { command in
      if captured == nil { captured = command }
    }
    let samples = try loadSamples(name)
    detector.process(padded(samples))
    return captured
  }

  private func maxScores(for name: String, provider: OnnxExecutionProvider) throws -> (gravar: Float, parar: Float) {
    let detector = try WakeWordDetector(classifierProvider: provider)
    var maxG: Float = 0
    var maxP: Float = 0
    detector.onScoresForTesting = { g, p in
      if g > maxG { maxG = g }
      if p > maxP { maxP = p }
    }
    let samples = try loadSamples(name)
    detector.process(padded(samples))
    return (maxG, maxP)
  }

  func testRawScoresCoreMLvsCPU() throws {
    let all = gravarFixtures + pararFixtures
    for provider in [OnnxExecutionProvider.coreML, OnnxExecutionProvider.cpu] {
      let tag = provider == .coreML ? "CoreML" : "CPU"
      var lines: [String] = []
      for name in all {
        let s = try maxScores(for: name, provider: provider)
        lines.append(String(format: "%@ g=%.3f p=%.3f", name, s.gravar, s.parar))
      }
      let summary = "SCORES[\(tag)]: " + lines.joined(separator: " | ")
      os_log("%{public}@", log: recallLog, type: .default, summary)
      print(summary)
    }
  }

  func testGravarClipsFireStart() throws {
    var hits = 0
    var falseFires = 0
    var results: [String] = []
    for name in gravarFixtures {
      let command = try fireCommand(for: name)
      switch command {
      case .start:
        hits += 1
        results.append("\(name)=start")
      case .stop:
        falseFires += 1
        results.append("\(name)=stop(WRONG)")
      case nil:
        results.append("\(name)=none")
      }
    }
    os_log("RECALL RESULT: gravar %d/4 fired .start, false-fires %d — %{public}@",
           log: recallLog, type: .default, hits, falseFires, results.joined(separator: " "))
    print("RECALL RESULT: gravar \(hits)/4 fired .start, false-fires \(falseFires) — \(results.joined(separator: " "))")

    for name in gravarFixtures {
      let command = try fireCommand(for: name)
      XCTAssertEqual(command, .start, "\(name) should fire .start")
    }
  }

  func testPararClipsFireStop() throws {
    var hits = 0
    var falseFires = 0
    var results: [String] = []
    for name in pararFixtures {
      let command = try fireCommand(for: name)
      switch command {
      case .stop:
        hits += 1
        results.append("\(name)=stop")
      case .start:
        falseFires += 1
        results.append("\(name)=start(WRONG)")
      case nil:
        results.append("\(name)=none")
      }
    }
    os_log("RECALL RESULT: parar %d/4 fired .stop, false-fires %d — %{public}@",
           log: recallLog, type: .default, hits, falseFires, results.joined(separator: " "))
    print("RECALL RESULT: parar \(hits)/4 fired .stop, false-fires \(falseFires) — \(results.joined(separator: " "))")

    for name in pararFixtures {
      let command = try fireCommand(for: name)
      XCTAssertEqual(command, .stop, "\(name) should fire .stop")
    }
  }
}
