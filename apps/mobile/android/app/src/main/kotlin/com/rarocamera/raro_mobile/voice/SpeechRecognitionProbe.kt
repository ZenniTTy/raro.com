package com.rarocamera.raro_mobile.voice

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log

object SpeechRecognitionProbe {
  private const val TAG = "RaroVoiceProbe"

  fun probe(context: Context) {
    Log.i(TAG, "SDK_INT=${Build.VERSION.SDK_INT}")
    val onDeviceAvailable = SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
    Log.i(TAG, "isOnDeviceRecognitionAvailable=$onDeviceAvailable")

    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
      Log.i(TAG, "SDK<33: checkRecognitionSupport indisponivel; fallback path em producao")
      return
    }
    if (!onDeviceAvailable) {
      Log.w(TAG, "on-device recognition indisponivel neste device")
      return
    }

    val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
    }
    recognizer.checkRecognitionSupport(
      intent,
      context.mainExecutor,
      object : RecognitionSupportCallback {
        override fun onSupportResult(recognitionSupport: RecognitionSupport) {
          Log.i(TAG, "installed=${recognitionSupport.installedOnDeviceLanguages}")
          Log.i(TAG, "supported=${recognitionSupport.supportedOnDeviceLanguages}")
          Log.i(TAG, "pending=${recognitionSupport.pendingOnDeviceLanguages}")
          val ptInstalled = recognitionSupport.installedOnDeviceLanguages.any {
            it.equals("pt-BR", ignoreCase = true) || it.startsWith("pt", ignoreCase = true)
          }
          Log.i(TAG, "PT_BR_ON_DEVICE_INSTALLED=$ptInstalled")
          recognizer.destroy()
        }

        override fun onError(error: Int) {
          Log.w(TAG, "checkRecognitionSupport error=$error")
          recognizer.destroy()
        }
      },
    )
  }
}
