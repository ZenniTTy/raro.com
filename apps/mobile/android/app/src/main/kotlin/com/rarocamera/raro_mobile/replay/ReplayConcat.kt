package com.rarocamera.raro_mobile.replay

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.max

private const val TAG = "RaroReplayConcat"
private const val MIN_BUFFER_BYTES = 1_048_576

class ReplayConcatException(message: String, cause: Throwable? = null) : Exception(message, cause)

object ReplayConcat {
  fun concat(inputs: List<File>, output: File): Long {
    output.parentFile?.mkdirs()
    if (output.exists() && !output.delete()) {
      Log.w(TAG, "could not delete existing output ${output.name}")
    }

    var muxer: MediaMuxer? = null
    var muxerStarted = false
    var videoOut = -1
    var audioOut = -1
    var timelineUs = 0L
    var wrote = false

    try {
      for (file in inputs) {
        if (!file.exists() || file.length() == 0L) {
          Log.w(TAG, "skipping missing segment ${file.name}")
          continue
        }
        val extractor = MediaExtractor()
        try {
          extractor.setDataSource(file.absolutePath)
          val videoIdx = findTrack(extractor, "video/")
          if (videoIdx < 0) {
            Log.w(TAG, "skipping segment without video ${file.name}")
            continue
          }
          val audioIdx = findTrack(extractor, "audio/")
          val videoFormat = extractor.getTrackFormat(videoIdx)
          val audioFormat = if (audioIdx >= 0) extractor.getTrackFormat(audioIdx) else null

          if (muxer == null) {
            val created = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            videoOut = created.addTrack(videoFormat)
            if (audioFormat != null) {
              audioOut = created.addTrack(audioFormat)
            }
            if (videoFormat.containsKey(MediaFormat.KEY_ROTATION)) {
              created.setOrientationHint(videoFormat.getInteger(MediaFormat.KEY_ROTATION))
            }
            created.start()
            muxer = created
            muxerStarted = true
          }

          val activeMuxer = muxer ?: continue
          extractor.selectTrack(videoIdx)
          if (audioIdx >= 0 && audioOut >= 0) {
            extractor.selectTrack(audioIdx)
          }

          val buffer = bufferFor(videoFormat, audioFormat)
          val info = MediaCodec.BufferInfo()
          var videoOrigin: Long? = null
          var lastVideoPts = timelineUs
          var sawKeyframe = false
          val videoDurationUs = durationOf(videoFormat)

          while (true) {
            buffer.clear()
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) break
            val track = extractor.sampleTrackIndex
            val pts = extractor.sampleTime
            val flags = extractor.sampleFlags

            if (track == videoIdx) {
              if (!sawKeyframe) {
                if (flags and MediaCodec.BUFFER_FLAG_KEY_FRAME == 0) {
                  extractor.advance()
                  continue
                }
                sawKeyframe = true
                videoOrigin = pts
              }
              val origin = videoOrigin ?: pts
              val outPts = ReplaySegmentRing.alignedPts(pts, origin, timelineUs)
              if (outPts < 0) {
                extractor.advance()
                continue
              }
              info.offset = 0
              info.size = size
              info.presentationTimeUs = outPts
              info.flags = flags
              activeMuxer.writeSampleData(videoOut, buffer, info)
              lastVideoPts = outPts
              wrote = true
            } else if (track == audioIdx && audioOut >= 0) {
              val origin = videoOrigin
              if (origin == null) {
                extractor.advance()
                continue
              }
              val relative = pts - origin
              if (relative < 0 || (videoDurationUs > 0 && relative > videoDurationUs)) {
                extractor.advance()
                continue
              }
              val outPts = ReplaySegmentRing.alignedPts(pts, origin, timelineUs)
              info.offset = 0
              info.size = size
              info.presentationTimeUs = outPts
              info.flags = flags
              activeMuxer.writeSampleData(audioOut, buffer, info)
              wrote = true
            }
            extractor.advance()
          }

          timelineUs = if (videoDurationUs > 0) {
            timelineUs + videoDurationUs
          } else {
            lastVideoPts
          }
        } catch (e: Throwable) {
          Log.w(TAG, "skipping unreadable segment ${file.name}", e)
        } finally {
          extractor.release()
        }
      }

      if (!wrote || muxer == null) {
        throw ReplayConcatException("no usable chunks")
      }
      muxer.stop()
      muxerStarted = false
      return max(timelineUs / 1000L, 0L)
    } catch (e: Throwable) {
      if (output.exists()) {
        output.delete()
      }
      if (e is ReplayConcatException) throw e
      throw ReplayConcatException(e.message ?: e.javaClass.simpleName, e)
    } finally {
      val active = muxer
      if (active != null) {
        if (muxerStarted) {
          try {
            active.stop()
          } catch (e: Throwable) {
            Log.w(TAG, "muxer stop failed", e)
          }
        }
        try {
          active.release()
        } catch (e: Throwable) {
          Log.w(TAG, "muxer release failed", e)
        }
      }
    }
  }

  private fun findTrack(extractor: MediaExtractor, mimePrefix: String): Int {
    for (i in 0 until extractor.trackCount) {
      val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
      if (mime.startsWith(mimePrefix)) return i
    }
    return -1
  }

  private fun durationOf(format: MediaFormat): Long {
    if (!format.containsKey(MediaFormat.KEY_DURATION)) return 0L
    return format.getLong(MediaFormat.KEY_DURATION)
  }

  private fun bufferFor(videoFormat: MediaFormat, audioFormat: MediaFormat?): ByteBuffer {
    var cap = MIN_BUFFER_BYTES
    if (videoFormat.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
      cap = max(cap, videoFormat.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE))
    }
    if (audioFormat != null && audioFormat.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
      cap = max(cap, audioFormat.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE))
    }
    return ByteBuffer.allocateDirect(cap)
  }
}
