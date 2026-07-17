package com.rarocamera.raro_mobile.camera

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.camera.video.AudioStats
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode
import java.io.File
import java.util.concurrent.Executor

private const val TAG = "RaroRecording"

fun raroTempName(sessionId: String): String = "raro_$sessionId.mp4"

class RecordingController(
  private val context: Context,
  private val mainExecutor: Executor,
) {
  interface RecordingCallbacks {
    fun onStarted(sessionId: String)
    fun onFinished(path: String, durationMs: Long)
    fun onFailed(code: CameraErrorCode, message: String?)
  }

  private var recording: Recording? = null

  fun isRecording(): Boolean = recording != null

  fun tempFileFor(sessionId: String): File = File(context.cacheDir, raroTempName(sessionId))

  @SuppressLint("MissingPermission")
  fun start(
    videoCapture: VideoCapture<Recorder>,
    sessionId: String,
    callbacks: RecordingCallbacks,
  ) {
    if (recording != null) {
      callbacks.onFailed(CameraErrorCode.ALREADY_RUNNING, "recording already in progress")
      return
    }
    val target = tempFileFor(sessionId)
    val outputOptions = FileOutputOptions.Builder(target).build()
    recording = videoCapture.output
      .prepareRecording(context, outputOptions)
      .withAudioEnabled()
      .start(mainExecutor) { event ->
        when (event) {
          is VideoRecordEvent.Start -> callbacks.onStarted(sessionId)
          is VideoRecordEvent.Finalize -> {
            recording = null
            if (event.hasError()) {
              Log.w(TAG, "recording finalize error code=${event.error}", event.cause)
              callbacks.onFailed(
                CameraErrorCode.SESSION_FAILED,
                "recording failed error=${event.error}",
              )
            } else {
              val audioState = event.recordingStats.audioStats.audioState
              if (audioState != AudioStats.AUDIO_STATE_ACTIVE &&
                audioState != AudioStats.AUDIO_STATE_DISABLED
              ) {
                Log.w(TAG, "recording finalized with degraded audio state=$audioState")
              }
              val durationMs = event.recordingStats.recordedDurationNanos / 1_000_000
              callbacks.onFinished(target.absolutePath, durationMs)
            }
          }
          else -> Unit
        }
      }
  }

  fun stop() {
    recording?.stop()
  }
}
