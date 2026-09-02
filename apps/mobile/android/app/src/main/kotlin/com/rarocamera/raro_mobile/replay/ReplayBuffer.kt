package com.rarocamera.raro_mobile.replay

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import java.io.File
import java.util.UUID
import java.util.concurrent.Executor
import java.util.concurrent.Executors

private const val TAG = "RaroReplay"

class ReplayBuffer(
  private val context: Context,
  private val mainExecutor: Executor,
  private val chunkSeconds: Int = ReplaySegmentRing.CHUNK_SECONDS,
) {
  private val handler = Handler(Looper.getMainLooper())
  private val concatExecutor = Executors.newSingleThreadExecutor()
  private var ring = ReplaySegmentRing(windowSeconds = 15, chunkSeconds = chunkSeconds)
  private var videoCapture: VideoCapture<Recorder>? = null
  private var recording: Recording? = null
  private var buffering = false
  private var paused = false
  private var cycle = 0
  private var segmentIndex = 0
  private var stopRunnable: Runnable? = null
  private var pendingFrozen: ((List<ReplaySegment>) -> Unit)? = null

  var onSaved: ((File, Long) -> Unit)? = null
  var onFailed: ((String, String?) -> Unit)? = null

  fun enable(seconds: Int) {
    deleteFiles(ring.setWindow(seconds))
    buffering = true
    Log.i(TAG, "replay buffering started window=${seconds}s chunk=${chunkSeconds}s")
    if (!paused && recording == null) {
      startSegment()
    }
  }

  fun disable() {
    cycle += 1
    buffering = false
    paused = false
    pendingFrozen = null
    cancelScheduledStop()
    stopQuietly()
    recording = null
    deleteFiles(ring.reset())
  }

  fun attach(vc: VideoCapture<Recorder>) {
    videoCapture = vc
    if (ReplaySegmentRing.shouldCycle(buffering, paused) && recording == null) {
      startSegment()
    }
  }

  fun releaseCapture() {
    cycle += 1
    cancelScheduledStop()
    stopQuietly()
    recording = null
    videoCapture = null
    pendingFrozen = null
    deleteFiles(ring.reset())
  }

  fun pauseEncoder() {
    if (!buffering) return
    paused = true
    cycle += 1
    cancelScheduledStop()
    stopQuietly()
    recording = null
    pendingFrozen = null
    deleteFiles(ring.reset())
  }

  fun resumeEncoder() {
    if (!buffering) return
    paused = false
    if (recording == null) {
      startSegment()
    }
  }

  fun freeze(onFrozen: (List<ReplaySegment>) -> Unit) {
    paused = true
    cancelScheduledStop()
    val rec = recording
    if (rec == null) {
      onFrozen(ring.windowSegments())
      return
    }
    pendingFrozen = onFrozen
    rec.stop()
  }

  fun resume() {
    paused = false
    if (buffering && recording == null) {
      startSegment()
    }
  }

  fun saveStandalone() {
    if (!buffering) {
      onFailed?.invoke("notBuffering", null)
      return
    }
    val resumeAfter = !paused
    val export = {
      val segments = ring.windowSegments()
      if (segments.isEmpty()) {
        onFailed?.invoke("noChunks", null)
        if (resumeAfter) resume()
      } else {
        concatExecutor.execute {
          val out = File(context.cacheDir, "raro_replay_${UUID.randomUUID()}.mp4")
          try {
            val durationMs = ReplayConcat.concat(segments.map { it.file }, out)
            mainExecutor.execute {
              Log.i(TAG, "saveReplay ok durationMs=$durationMs")
              onSaved?.invoke(out, durationMs)
              if (resumeAfter) resume()
            }
          } catch (e: Throwable) {
            Log.w(TAG, "saveReplay concat failed", e)
            mainExecutor.execute {
              onFailed?.invoke("exportFailed", e.message)
              if (resumeAfter) resume()
            }
          }
        }
      }
    }
    if (recording != null) {
      freeze { export() }
    } else {
      export()
    }
  }

  fun concatPreroll(
    preroll: List<ReplaySegment>,
    recordingFile: File,
    output: File,
    onDone: (Result<Long>) -> Unit,
  ) {
    concatExecutor.execute {
      try {
        val files = preroll.map { it.file } + recordingFile
        val durationMs = ReplayConcat.concat(files, output)
        mainExecutor.execute { onDone(Result.success(durationMs)) }
      } catch (e: Throwable) {
        Log.w(TAG, "preroll concat failed", e)
        mainExecutor.execute { onDone(Result.failure(e)) }
      }
    }
  }

  @SuppressLint("MissingPermission")
  private fun startSegment() {
    if (!ReplaySegmentRing.shouldCycle(buffering, paused)) return
    if (recording != null) return
    val vc = videoCapture ?: return
    val capturedCycle = cycle
    val index = segmentIndex
    segmentIndex += 1
    val file = File(context.cacheDir, "raro_seg_$index.mp4")
    if (file.exists()) {
      file.delete()
    }
    val options = FileOutputOptions.Builder(file).build()
    try {
      recording = vc.output
        .prepareRecording(context, options)
        .withAudioEnabled()
        .start(mainExecutor) { event ->
          if (capturedCycle != cycle) {
            if (event is VideoRecordEvent.Finalize) {
              file.delete()
            }
            return@start
          }
          when (event) {
            is VideoRecordEvent.Start -> scheduleStop()
            is VideoRecordEvent.Finalize -> {
              recording = null
              cancelScheduledStop()
              if (event.hasError()) {
                Log.w(TAG, "segment finalize error code=${event.error}", event.cause)
                file.delete()
              } else {
                val durationMs = event.recordingStats.recordedDurationNanos / 1_000_000
                deleteFiles(ring.append(ReplaySegment(file, durationMs)))
              }
              val cb = pendingFrozen
              pendingFrozen = null
              if (cb != null) {
                cb(ring.windowSegments())
              } else if (ReplaySegmentRing.shouldCycle(buffering, paused)) {
                startSegment()
              }
            }
            else -> Unit
          }
        }
    } catch (e: SecurityException) {
      Log.w(TAG, "replay segment start denied (mic)", e)
      buffering = false
    } catch (e: Throwable) {
      Log.w(TAG, "replay segment start failed", e)
    }
  }

  private fun scheduleStop() {
    cancelScheduledStop()
    val r = Runnable { recording?.stop() }
    stopRunnable = r
    handler.postDelayed(r, chunkSeconds * 1000L)
  }

  private fun cancelScheduledStop() {
    stopRunnable?.let { handler.removeCallbacks(it) }
    stopRunnable = null
  }

  private fun stopQuietly() {
    try {
      recording?.stop()
    } catch (e: Throwable) {
      Log.w(TAG, "segment stop failed", e)
    }
  }

  private fun deleteFiles(files: List<File>) {
    for (file in files) {
      if (file.exists() && !file.delete()) {
        Log.w(TAG, "failed to delete segment ${file.name}")
      }
    }
  }
}
