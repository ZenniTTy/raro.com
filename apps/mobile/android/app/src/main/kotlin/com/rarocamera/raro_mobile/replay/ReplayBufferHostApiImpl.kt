package com.rarocamera.raro_mobile.replay

import android.os.Handler
import android.os.Looper
import com.rarocamera.raro_mobile.camera.CameraManager
import com.rarocamera.raro_mobile.camera.CameraNativeException
import com.rarocamera.raro_mobile.camera.symbolicCode
import com.rarocamera.raro_mobile.generated.replay_buffer.FlutterError
import com.rarocamera.raro_mobile.generated.replay_buffer.ReplayBufferFlutterApi
import com.rarocamera.raro_mobile.generated.replay_buffer.ReplayBufferHostApi
import io.flutter.plugin.common.BinaryMessenger

class ReplayBufferHostApiImpl(
  private val cameraManager: CameraManager,
  messenger: BinaryMessenger,
) : ReplayBufferHostApi {
  private val main = Handler(Looper.getMainLooper())
  private val flutterApi = ReplayBufferFlutterApi(messenger)

  init {
    cameraManager.onReplaySaved = { path, durationMs ->
      main.post { flutterApi.onReplaySaved(path, durationMs) {} }
    }
    cameraManager.onReplayFailed = { code, message ->
      main.post { flutterApi.onReplayFailed(code, message) {} }
    }
  }

  override fun enableReplayBuffer(seconds: Long) {
    cameraManager.enableReplayBuffer(seconds.toInt())
  }

  override fun disableReplayBuffer() {
    cameraManager.disableReplayBuffer()
  }

  override fun saveReplay() {
    try {
      cameraManager.saveReplay()
    } catch (e: CameraNativeException) {
      throw FlutterError(code = e.symbolicCode(), message = e.message, details = null)
    }
  }
}
