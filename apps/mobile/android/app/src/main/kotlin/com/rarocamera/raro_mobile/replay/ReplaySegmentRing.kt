package com.rarocamera.raro_mobile.replay

import java.io.File
import kotlin.math.ceil

data class ReplaySegment(
  val file: File,
  val durationMs: Long,
)

class ReplaySegmentRing(
  windowSeconds: Int,
  val chunkSeconds: Int = CHUNK_SECONDS,
) {
  var capacityCount: Int = capacity(windowSeconds, chunkSeconds)
    private set

  private val segments: MutableList<ReplaySegment> = mutableListOf()

  val stored: List<ReplaySegment>
    get() = segments.toList()

  fun append(segment: ReplaySegment): List<File> {
    segments.add(segment)
    return evictOverflow()
  }

  fun setWindow(seconds: Int): List<File> {
    capacityCount = capacity(seconds, chunkSeconds)
    return evictOverflow()
  }

  fun windowSegments(): List<ReplaySegment> = segments.toList()

  fun reset(): List<File> {
    val files = segments.map { it.file }
    segments.clear()
    return files
  }

  private fun evictOverflow(): List<File> {
    val evicted = mutableListOf<File>()
    while (segments.size > capacityCount) {
      evicted.add(segments.removeAt(0).file)
    }
    return evicted
  }

  companion object {
    const val CHUNK_SECONDS = 5

    fun capacity(windowSeconds: Int, chunkSeconds: Int): Int {
      if (chunkSeconds <= 0) return 1
      return ceil(windowSeconds.toDouble() / chunkSeconds.toDouble()).toInt() + 1
    }

    fun shouldCycle(buffering: Boolean, paused: Boolean): Boolean = buffering && !paused

    fun alignedPts(sampleTimeUs: Long, originUs: Long, timelineUs: Long): Long =
      timelineUs + (sampleTimeUs - originUs)
  }
}
