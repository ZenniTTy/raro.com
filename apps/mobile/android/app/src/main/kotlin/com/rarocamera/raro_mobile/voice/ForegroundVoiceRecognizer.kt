package com.rarocamera.raro_mobile.voice

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import com.rarocamera.raro_mobile.generated.voice.VoiceListeningState
import com.rarocamera.raro_mobile.generated.voice.WakeCommand

class ForegroundVoiceRecognizer(
  private val context: Context,
  private val onCommand: (WakeCommand) -> Unit,
  private val onState: (VoiceListeningState) -> Unit,
) {
  private val main = Handler(Looper.getMainLooper())
  private var recognizer: SpeechRecognizer? = null
  private var running = false
  private var cycle = 0
  private var benignRestarts = 0

  fun isAvailable(): Boolean =
    SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

  fun start() {
    if (running) return
    if (!isAvailable()) {
      onState(VoiceListeningState.UNAVAILABLE)
      return
    }
    running = true
    benignRestarts = 0
    launchSession()
  }

  fun stop() {
    running = false
    cycle++
    main.removeCallbacksAndMessages(null)
    recognizer?.destroy()
    recognizer = null
    onState(VoiceListeningState.IDLE)
  }

  private fun launchSession() {
    if (!running) return
    cycle++
    recognizer?.destroy()
    val r = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
    r.setRecognitionListener(cycleListener(cycle))
    recognizer = r
    r.startListening(recognizeIntent())
    onState(VoiceListeningState.LISTENING)
  }

  private fun recognizeIntent(): Intent =
    Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
      putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
    }

  private fun handleTranscripts(bundle: Bundle?): Boolean {
    val hits = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION) ?: return false
    for (t in hits) {
      val cmd = VoiceCommandParser.parse(t)
      if (cmd != null) {
        Log.i(TAG, "wake matched -> $cmd")
        onCommand(cmd)
        return true
      }
    }
    return false
  }

  private fun cycleListener(token: Int) = object : RecognitionListener {
    override fun onResults(results: Bundle?) {
      if (token != cycle) return
      handleTranscripts(results)
      relaunch(token, delayMs = 0, reason = "results")
    }

    override fun onPartialResults(partialResults: Bundle?) {
      if (token != cycle) return
      if (handleTranscripts(partialResults)) {
        relaunch(token, delayMs = 0, reason = "partial-match")
      }
    }

    override fun onError(error: Int) {
      if (token != cycle) return
      if (error == SpeechRecognizer.ERROR_NO_MATCH ||
        error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT
      ) {
        benignRestarts++
        Log.d(TAG, "benign error=$error, refreshing (count=$benignRestarts)")
        relaunch(token, delayMs = BENIGN_REFRESH_MS, reason = "benign")
        return
      }
      Log.w(TAG, "recognizer error=$error, backing off")
      relaunch(token, delayMs = ERROR_BACKOFF_MS, reason = "error")
    }

    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
  }

  private fun relaunch(token: Int, delayMs: Long, reason: String) {
    if (!running || token != cycle) return
    main.postDelayed({
      if (running && token == cycle) launchSession()
    }, delayMs)
  }

  private companion object {
    const val TAG = "RaroVoice"
    const val BENIGN_REFRESH_MS = 250L
    const val ERROR_BACKOFF_MS = 500L
  }
}
