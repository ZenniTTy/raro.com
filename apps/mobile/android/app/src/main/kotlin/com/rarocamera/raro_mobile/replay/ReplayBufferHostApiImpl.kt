package com.rarocamera.raro_mobile.replay

import android.util.Log
import com.rarocamera.raro_mobile.camera.CameraManager
import com.rarocamera.raro_mobile.generated.replay_buffer.ReplayBufferHostApi

class ReplayBufferHostApiImpl(
  private val cameraManager: CameraManager,
) : ReplayBufferHostApi {
  override fun enableReplayBuffer(seconds: Long) {
    Log.i("RaroReplaySpike", "enableReplayBuffer($seconds) — TEMP: firing ADR-0031 spike-gate")
    cameraManager.runReplaySpike(segments = 5, chunkSeconds = 2)
  }

  override fun disableReplayBuffer() {
    Log.i("RaroReplaySpike", "disableReplayBuffer — TEMP no-op during spike")
  }

  override fun saveReplay() {
    Log.i("RaroReplaySpike", "saveReplay — TEMP no-op during spike")
  }
}
