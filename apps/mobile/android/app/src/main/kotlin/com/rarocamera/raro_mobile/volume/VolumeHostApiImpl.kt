package com.rarocamera.raro_mobile.volume

import android.view.KeyEvent
import com.rarocamera.raro_mobile.generated.volume.VolumeDirection
import com.rarocamera.raro_mobile.generated.volume.VolumeFlutterApi
import com.rarocamera.raro_mobile.generated.volume.VolumeHostApi

class VolumeHostApiImpl(
  private val flutterApi: VolumeFlutterApi,
) : VolumeHostApi {
  @Volatile
  var isListening: Boolean = false
    private set

  override fun isAvailable(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(true))
  }

  override fun startListening() {
    isListening = true
  }

  override fun stopListening() {
    isListening = false
  }

  fun onKeyEvent(event: KeyEvent): Boolean {
    if (!isListening) return false
    val direction =
      when (event.keyCode) {
        KeyEvent.KEYCODE_VOLUME_UP -> VolumeDirection.UP
        KeyEvent.KEYCODE_VOLUME_DOWN -> VolumeDirection.DOWN
        else -> return false
      }
    if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
      flutterApi.onVolumePressed(direction) {}
    }
    return true
  }
}
