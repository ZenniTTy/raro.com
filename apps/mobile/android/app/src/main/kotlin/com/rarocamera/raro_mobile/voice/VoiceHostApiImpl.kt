package com.rarocamera.raro_mobile.voice

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.rarocamera.raro_mobile.generated.voice.VoiceFlutterApi
import com.rarocamera.raro_mobile.generated.voice.VoiceHostApi
import com.rarocamera.raro_mobile.generated.voice.VoiceListeningState
import com.rarocamera.raro_mobile.generated.voice.WakeCommand

class VoiceHostApiImpl(
  private val context: Context,
  private val flutterApi: VoiceFlutterApi,
) : VoiceHostApi {
  private val main = Handler(Looper.getMainLooper())
  private val foreground = ForegroundVoiceRecognizer(
    context,
    onCommand = { cmd -> emitCommand(cmd) },
    onState = { state -> emitState(state) },
  )

  var wantsListening: Boolean = false
    private set

  init {
    VoiceBackgroundService.commandListener = { cmd -> emitCommand(cmd) }
  }

  override fun isAvailable(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(foreground.isAvailable()))
  }

  override fun startListening() {
    wantsListening = true
    main.post { foreground.start() }
  }

  override fun stopListening() {
    wantsListening = false
    main.post { foreground.stop() }
  }

  fun moveToBackground() {
    if (!wantsListening) return
    main.post {
      foreground.stop()
      VoiceBackgroundService.start(context)
    }
  }

  fun moveToForeground() {
    if (!wantsListening) return
    main.post {
      VoiceBackgroundService.stop(context)
      foreground.start()
    }
  }

  private fun emitCommand(cmd: WakeCommand) {
    main.post { flutterApi.onWakeDetected(cmd) {} }
  }

  private fun emitState(state: VoiceListeningState) {
    main.post { flutterApi.onListeningStateChanged(state) {} }
  }
}
