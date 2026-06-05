import AVFoundation
import XCTest
@testable import Runner

final class CameraManagerCapabilitiesTests: XCTestCase {
  func testResolutionForKnownDimensions() {
    XCTAssertEqual(CameraManager.resolutionForDimensions(width: 3840, height: 2160), .uhd4k)
    XCTAssertEqual(CameraManager.resolutionForDimensions(width: 1920, height: 1080), .fhd1080)
    XCTAssertEqual(CameraManager.resolutionForDimensions(width: 1280, height: 720), .hd720)
  }

  func testResolutionForPortraitDimensionsIsOrientationAgnostic() {
    XCTAssertEqual(CameraManager.resolutionForDimensions(width: 2160, height: 3840), .uhd4k)
    XCTAssertEqual(CameraManager.resolutionForDimensions(width: 1080, height: 1920), .fhd1080)
  }

  func testResolutionForUnknownDimensionsIsNil() {
    XCTAssertNil(CameraManager.resolutionForDimensions(width: 1920, height: 1440))
    XCTAssertNil(CameraManager.resolutionForDimensions(width: 640, height: 480))
  }

  func testRequiresPhysicalLensOnlyForUhd4k60() {
    XCTAssertTrue(CameraManager.requiresPhysicalLens(resolution: .uhd4k, fps: .fps60))
    XCTAssertFalse(CameraManager.requiresPhysicalLens(resolution: .uhd4k, fps: .fps30))
    XCTAssertFalse(CameraManager.requiresPhysicalLens(resolution: .fhd1080, fps: .fps60))
    XCTAssertFalse(CameraManager.requiresPhysicalLens(resolution: nil, fps: nil))
  }

  func testMergePrefersVirtualAndMarksPhysicalOnlyCombos() {
    let virtual: Set<CameraManager.RawFormat> = [
      .init(resolution: .hd720, fps: .fps30),
      .init(resolution: .fhd1080, fps: .fps30),
      .init(resolution: .fhd1080, fps: .fps60),
      .init(resolution: .uhd4k, fps: .fps30),
    ]
    let physical: Set<CameraManager.RawFormat> = [
      .init(resolution: .fhd1080, fps: .fps60),
      .init(resolution: .uhd4k, fps: .fps30),
      .init(resolution: .uhd4k, fps: .fps60),
    ]

    let merged = CameraManager.mergeFormatCapabilities(virtual: virtual, physical: physical)

    let only4k60 = merged.filter { $0.resolution == .uhd4k && $0.fps == .fps60 }
    XCTAssertEqual(only4k60.count, 1)
    XCTAssertTrue(only4k60.first?.requiresPhysicalLens ?? false)

    let fhd60 = merged.filter { $0.resolution == .fhd1080 && $0.fps == .fps60 }
    XCTAssertEqual(fhd60.count, 1)
    XCTAssertFalse(fhd60.first?.requiresPhysicalLens ?? true)

    let uhd30 = merged.filter { $0.resolution == .uhd4k && $0.fps == .fps30 }
    XCTAssertEqual(uhd30.count, 1)
    XCTAssertFalse(uhd30.first?.requiresPhysicalLens ?? true)
  }

  func testMergeWithEmptyPhysicalHasNo4k60() {
    let virtual: Set<CameraManager.RawFormat> = [
      .init(resolution: .fhd1080, fps: .fps60),
      .init(resolution: .uhd4k, fps: .fps30),
    ]
    let merged = CameraManager.mergeFormatCapabilities(virtual: virtual, physical: [])
    XCTAssertFalse(merged.contains { $0.resolution == .uhd4k && $0.fps == .fps60 })
  }
}
