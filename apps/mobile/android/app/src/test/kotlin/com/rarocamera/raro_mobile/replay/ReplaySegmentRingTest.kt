package com.rarocamera.raro_mobile.replay

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReplaySegmentRingTest {
  @Test
  fun capacity_matches_ios_formula() {
    assertEquals(31, ReplaySegmentRing.capacity(windowSeconds = 30, chunkSeconds = 1))
    assertEquals(16, ReplaySegmentRing.capacity(windowSeconds = 15, chunkSeconds = 1))
    assertEquals(16, ReplaySegmentRing.capacity(windowSeconds = 30, chunkSeconds = 2))
  }

  @Test
  fun capacity_for_android_5s_chunks() {
    assertEquals(4, ReplaySegmentRing.capacity(windowSeconds = 15, chunkSeconds = 5))
    assertEquals(7, ReplaySegmentRing.capacity(windowSeconds = 30, chunkSeconds = 5))
  }

  @Test
  fun capacity_guards_non_positive_chunk() {
    assertEquals(1, ReplaySegmentRing.capacity(windowSeconds = 15, chunkSeconds = 0))
    assertEquals(1, ReplaySegmentRing.capacity(windowSeconds = 15, chunkSeconds = -1))
  }

  @Test
  fun append_beyond_capacity_keeps_newest_in_order() {
    val ring = ReplaySegmentRing(windowSeconds = 15, chunkSeconds = 5)
    val evicted = mutableListOf<File>()
    for (i in 0 until 6) {
      evicted += ring.append(segment("seg$i"))
    }
    assertEquals(
      listOf("seg2.mp4", "seg3.mp4", "seg4.mp4", "seg5.mp4"),
      ring.stored.map { it.file.name },
    )
    assertEquals(listOf("seg0.mp4", "seg1.mp4"), evicted.map { it.name })
  }

  @Test
  fun window_segments_are_all_retained_when_within_capacity() {
    val ring = ReplaySegmentRing(windowSeconds = 30, chunkSeconds = 5)
    for (i in 0 until 4) {
      ring.append(segment("c$i"))
    }
    assertEquals(4, ring.windowSegments().size)
  }

  @Test
  fun set_window_recomputes_capacity_and_evicts_excess() {
    val ring = ReplaySegmentRing(windowSeconds = 30, chunkSeconds = 5)
    for (i in 0 until 7) {
      ring.append(segment("c$i"))
    }
    val evicted = ring.setWindow(15)
    assertEquals(4, ring.stored.size)
    assertEquals(3, evicted.size)
    assertEquals("c3.mp4", ring.stored.first().file.name)
  }

  @Test
  fun reset_clears_and_returns_all() {
    val ring = ReplaySegmentRing(windowSeconds = 15, chunkSeconds = 5)
    for (i in 0 until 3) {
      ring.append(segment("c$i"))
    }
    val cleared = ring.reset()
    assertEquals(3, cleared.size)
    assertTrue(ring.stored.isEmpty())
  }

  @Test
  fun window_segments_returns_a_copy() {
    val ring = ReplaySegmentRing(windowSeconds = 15, chunkSeconds = 5)
    for (i in 0 until 2) {
      ring.append(segment("c$i"))
    }
    val snapshot = ring.windowSegments()
    ring.append(segment("c2"))
    assertEquals(2, snapshot.size)
    assertEquals(3, ring.windowSegments().size)
  }

  @Test
  fun should_cycle_only_when_buffering_and_not_paused() {
    assertTrue(ReplaySegmentRing.shouldCycle(buffering = true, paused = false))
    assertFalse(ReplaySegmentRing.shouldCycle(buffering = true, paused = true))
    assertFalse(ReplaySegmentRing.shouldCycle(buffering = false, paused = false))
    assertFalse(ReplaySegmentRing.shouldCycle(buffering = false, paused = true))
  }

  @Test
  fun aligned_pts_anchors_audio_to_video_origin_so_drift_does_not_accumulate() {
    val seg0AudioOut = ReplaySegmentRing.alignedPts(
      sampleTimeUs = 1_640_000,
      originUs = 0,
      timelineUs = 0,
    )
    val timelineAfterSeg0 = 1_670_000L
    val seg1AudioOut = ReplaySegmentRing.alignedPts(
      sampleTimeUs = 0,
      originUs = 0,
      timelineUs = timelineAfterSeg0,
    )
    assertEquals(1_640_000L, seg0AudioOut)
    assertEquals(1_670_000L, seg1AudioOut)
  }

  private fun segment(stem: String): ReplaySegment =
    ReplaySegment(file = File("/tmp/$stem.mp4"), durationMs = 5000)
}
