import XCTest
@testable import Runner

final class ReplayRingTests: XCTestCase {
  func testCapacityForWindowAndChunkDuration() {
    XCTAssertEqual(ReplayRing.capacity(windowSeconds: 30, chunkSeconds: 1), 31)
    XCTAssertEqual(ReplayRing.capacity(windowSeconds: 15, chunkSeconds: 1), 16)
    XCTAssertEqual(ReplayRing.capacity(windowSeconds: 30, chunkSeconds: 2), 16)
  }

  func testAppendBeyondCapacityKeepsNewestInOrder() {
    var ring = ReplayRing(windowSeconds: 3, chunkSeconds: 1) // capacity 4
    let urls = (0..<6).map { URL(fileURLWithPath: "/tmp/chunk\($0).mp4") }
    var evicted: [URL] = []
    for u in urls { evicted.append(contentsOf: ring.append(Chunk(url: u, durationMs: 1000))) }
    XCTAssertEqual(ring.chunks.map { $0.url.lastPathComponent },
                   ["chunk2.mp4", "chunk3.mp4", "chunk4.mp4", "chunk5.mp4"])
    XCTAssertEqual(evicted.map { $0.lastPathComponent }, ["chunk0.mp4", "chunk1.mp4"])
  }

  func testWindowChunksAreAllRetainedWhenWithinWindow() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1)
    for i in 0..<10 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    XCTAssertEqual(ring.windowChunks().count, 10)
  }

  func testSetWindowRecomputesCapacityAndEvictsExcess() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1) // capacity 31
    for i in 0..<20 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    let evicted = ring.setWindow(seconds: 15) // capacity 16 -> evict oldest 4
    XCTAssertEqual(ring.chunks.count, 16)
    XCTAssertEqual(evicted.count, 4)
    XCTAssertEqual(ring.chunks.first?.url.lastPathComponent, "c4.mp4")
  }

  func testResetClearsAndReturnsAll() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1)
    for i in 0..<5 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    let cleared = ring.reset()
    XCTAssertEqual(cleared.count, 5)
    XCTAssertTrue(ring.chunks.isEmpty)
  }

  func testWindowChunksReturnsValueCopyNotMutatingRing() {
    var ring = ReplayRing(windowSeconds: 30, chunkSeconds: 1)
    for i in 0..<3 { _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c\(i).mp4"), durationMs: 1000)) }
    let snapshot = ring.windowChunks()
    _ = ring.append(Chunk(url: URL(fileURLWithPath: "/tmp/c3.mp4"), durationMs: 1000))
    XCTAssertEqual(snapshot.count, 3, "snapshot must be a value copy, immune to later appends")
    XCTAssertEqual(ring.windowChunks().count, 4)
  }

  func testShouldAppendOnlyWhenBufferingAndNotPaused() {
    XCTAssertTrue(ReplayBuffer.shouldAppend(buffering: true, paused: false))
    XCTAssertFalse(ReplayBuffer.shouldAppend(buffering: true, paused: true),
                   "paused (recording in progress) must stop the ring from duplicating G1 footage")
    XCTAssertFalse(ReplayBuffer.shouldAppend(buffering: false, paused: false))
    XCTAssertFalse(ReplayBuffer.shouldAppend(buffering: false, paused: true))
  }
}
