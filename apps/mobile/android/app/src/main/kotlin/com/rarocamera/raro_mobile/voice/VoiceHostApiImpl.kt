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

  var wantsListening: Boolean = false
    private set

  init {
    VoiceBackgroundService.commandListener = { cmd -> emitCommand(cmd) }
    VoiceBackgroundService.onUnavailable = {
      main.post {
        wantsListening = false
        emitState(VoiceListeningState.UNAVAILABLE)
      }
    }
    VoiceBackgroundService.onListening = { main.post { emitState(VoiceListeningState.LISTENING) } }
  }

  override fun isAvailable(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(VoskWakeEngine.isModelAvailable(context)))
  }

  override fun startListening() {
    wantsListening = true
    main.post {
      if (!VoiceBackgroundService.start(context)) {
        wantsListening = false
        emitState(VoiceListeningState.UNAVAILABLE)
      }
    }
  }

  override fun stopListening() {
    wantsListening = false
    main.post {
      VoiceBackgroundService.stop(context)
      emitState(VoiceListeningState.IDLE)
    }
  }

  fun dispose() {
    wantsListening = false
    main.removeCallbacksAndMessages(null)
    VoiceBackgroundService.stop(context)
    VoiceBackgroundService.commandListener = null
    VoiceBackgroundService.onUnavailable = null
    VoiceBackgroundService.onListening = null
  }

  private fun emitCommand(cmd: WakeCommand) {
    main.post { flutterApi.onWakeDetected(cmd) {} }
  }

  private fun emitState(state: VoiceListeningState) {
    main.post { flutterApi.onListeningStateChanged(state) {} }
  }
}
