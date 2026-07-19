package com.rarocamera.raro_mobile.replay

import android.annotation.SuppressLint
import android.content.Context
import android.os.SystemClock
import android.util.Log
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import java.io.File
import java.util.concurrent.Executor

private const val TAG = "RaroReplaySpike"

/**
 * ADR-0031 spike-gate (TEMPORARY / descartável). Mede o gap real de emenda ao ciclar
 * `Recording` do CameraX em segmentos, no device (M54), ANTES de comprometer a Rota D.
 *
 * NÃO é a feature. Produz apenas medição em log + arquivos .mp4 no cacheDir para ffprobe.
 * Remover ao concluir o gate (aprovado ou reprovado).
 */
class ReplaySpikeGate(
  private val context: Context,
  private val mainExecutor: Executor,
) {
  private var active: Recording? = null
  private var segmentIndex = 0
  private var totalSegments = 0
  private var chunkMs = 0L
  private var lastStopRequestedAt = 0L
  private var lastFinalizeAt = 0L
  private var segmentStartedAt = 0L
  private val gapsStopToStart = mutableListOf<Long>()
  private val gapsFinalizeToStart = mutableListOf<Long>()

  @SuppressLint("MissingPermission")
  fun run(
    videoCapture: VideoCapture<Recorder>,
    segments: Int,
    chunkSeconds: Int,
  ) {
    Log.i(TAG, "SPIKE START segments=$segments chunkSeconds=$chunkSeconds — files in cacheDir/raro_spike_*.mp4")
    segmentIndex = 0
    totalSegments = segments
    chunkMs = chunkSeconds * 1000L
    gapsStopToStart.clear()
    gapsFinalizeToStart.clear()
    startSegment(videoCapture)
  }

  @SuppressLint("MissingPermission")
  private fun startSegment(videoCapture: VideoCapture<Recorder>) {
    val file = File(context.cacheDir, "raro_spike_$segmentIndex.mp4")
    file.delete()
    val requestedStartAt = SystemClock.elapsedRealtime()
    if (segmentIndex > 0) {
      val gapStopToStart = requestedStartAt - lastStopRequestedAt
      val gapFinalizeToStart = requestedStartAt - lastFinalizeAt
      gapsStopToStart.add(gapStopToStart)
      gapsFinalizeToStart.add(gapFinalizeToStart)
      Log.i(
        TAG,
        "EMENDA seg${segmentIndex - 1}->seg$segmentIndex " +
          "gap_stopReq_to_startReq=${gapStopToStart}ms " +
          "gap_finalize_to_startReq=${gapFinalizeToStart}ms",
      )
    }
    val options = FileOutputOptions.Builder(file).build()
    active = videoCapture.output
      .prepareRecording(context, options)
      .withAudioEnabled()
      .start(mainExecutor) { event ->
        when (event) {
          is VideoRecordEvent.Start -> {
            segmentStartedAt = SystemClock.elapsedRealtime()
            Log.i(TAG, "seg$segmentIndex STARTED at=${segmentStartedAt}")
            mainExecutor.execute {
              scheduleStop(videoCapture)
            }
          }
          is VideoRecordEvent.Finalize -> {
            lastFinalizeAt = SystemClock.elapsedRealtime()
            val durMs = event.recordingStats.recordedDurationNanos / 1_000_000
            Log.i(
              TAG,
              "seg$segmentIndex FINALIZE err=${if (event.hasError()) event.error else 0} " +
                "durMs=$durMs finalizeAt=$lastFinalizeAt file=${file.absolutePath}",
            )
            active = null
            segmentIndex += 1
            if (segmentIndex < totalSegments) {
              startSegment(videoCapture)
            } else {
              report()
            }
          }
          else -> Unit
        }
      }
  }

  private fun scheduleStop(videoCapture: VideoCapture<Recorder>) {
    val startedAt = segmentStartedAt
    val stopper = object : Runnable {
      override fun run() {
        if (SystemClock.elapsedRealtime() - startedAt >= chunkMs) {
          lastStopRequestedAt = SystemClock.elapsedRealtime()
          Log.i(TAG, "seg$segmentIndex STOP requested at=$lastStopRequestedAt")
          active?.stop()
        } else {
          mainExecutor.execute(this)
        }
      }
    }
    mainExecutor.execute(stopper)
  }

  private fun report() {
    val avgStopStart = gapsStopToStart.average().takeIf { !it.isNaN() } ?: 0.0
    val maxStopStart = gapsStopToStart.maxOrNull() ?: 0L
    val avgFinStart = gapsFinalizeToStart.average().takeIf { !it.isNaN() } ?: 0.0
    val maxFinStart = gapsFinalizeToStart.maxOrNull() ?: 0L
    Log.i(
      TAG,
      "SPIKE REPORT emendas=${gapsStopToStart.size} " +
        "stopReq_to_startReq[avg=${"%.0f".format(avgStopStart)}ms max=${maxStopStart}ms] " +
        "finalize_to_startReq[avg=${"%.0f".format(avgFinStart)}ms max=${maxFinStart}ms] " +
        "GATE(ADR-0031: emenda<=150ms) => ${if (maxStopStart <= 150) "PASS(stopReq)" else "CHECK(stopReq>${maxStopStart})"}",
    )
    Log.i(TAG, "SPIKE DONE — puxar cacheDir/raro_spike_*.mp4 e rodar ffprobe (SPS/PPS + PTS audio)")
  }
}
