import AVFoundation
import UIKit
import XCTest
@testable import Runner

final class ThumbnailGeneratorTests: XCTestCase {
  func testThumbnailURLDerivesJpgFromVideoPath() {
    let videoURL = URL(fileURLWithPath: "/tmp/vault/abc123.mov")
    let thumbURL = ThumbnailGenerator.makeThumbnailURL(for: videoURL)
    XCTAssertEqual(thumbURL.pathExtension, "jpg")
    XCTAssertEqual(thumbURL.deletingPathExtension().lastPathComponent, "abc123")
    XCTAssertEqual(
      thumbURL.deletingLastPathComponent().path,
      videoURL.deletingLastPathComponent().path
    )
  }

  func testGenerateProducesDecodableJpegFromRealMov() throws {
    let videoURL = try makeOneFramePngBackedMov(width: 320, height: 240)
    defer { try? FileManager.default.removeItem(at: videoURL) }

    let generator = ThumbnailGenerator()
    let expectation = expectation(description: "thumbnail generated")
    var producedPath: String?
    var failure: Error?

    generator.generate(videoPath: videoURL.path) { result in
      switch result {
      case let .success(path): producedPath = path
      case let .failure(error): failure = error
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 10)

    if let failure { throw failure }
    let path = try XCTUnwrap(producedPath)
    XCTAssertTrue(path.hasSuffix(".jpg"))
    XCTAssertTrue(FileManager.default.fileExists(atPath: path))

    let data = try XCTUnwrap(FileManager.default.contents(atPath: path))
    let image = try XCTUnwrap(UIImage(data: data))
    XCTAssertGreaterThan(image.size.width, 0)
    XCTAssertGreaterThan(image.size.height, 0)
    try? FileManager.default.removeItem(atPath: path)
  }

  func testGenerateFailsForMissingFile() {
    let generator = ThumbnailGenerator()
    let expectation = expectation(description: "thumbnail fails")
    var failed = false
    generator.generate(videoPath: "/tmp/does-not-exist-\(UUID().uuidString).mov") { result in
      if case .failure = result { failed = true }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 10)
    XCTAssertTrue(failed)
  }

  private func makeOneFramePngBackedMov(width: Int, height: Int) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("thumb_fixture_\(UUID().uuidString).mov")
    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    let attributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
      kCVPixelBufferWidthKey as String: width,
      kCVPixelBufferHeightKey as String: height,
    ]
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: attributes
    )
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &pixelBuffer
    )
    let buffer = try XCTUnwrap(pixelBuffer)
    CVPixelBufferLockBaseAddress(buffer, [])
    if let base = CVPixelBufferGetBaseAddress(buffer) {
      memset(base, 128, CVPixelBufferGetDataSize(buffer))
    }
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: .zero)

    input.markAsFinished()
    let finished = expectation(description: "writer finished")
    writer.finishWriting { finished.fulfill() }
    wait(for: [finished], timeout: 10)
    return url
  }
}
