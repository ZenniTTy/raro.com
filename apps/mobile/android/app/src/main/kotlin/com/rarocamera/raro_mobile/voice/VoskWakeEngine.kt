package com.rarocamera.raro_mobile.voice

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import com.rarocamera.raro_mobile.generated.voice.WakeCommand
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import kotlin.concurrent.thread

class VoskWakeEngine(private val context: Context) : WakeEngine {
  @Volatile private var running = false
  @Volatile private var diedOnError = false
  private var worker: Thread? = null
  var onDied: (() -> Unit)? = null

  @SuppressLint("MissingPermission")
  override fun start(onCommand: (WakeCommand) -> Unit): Boolean {
    if (running) return true
    diedOnError = false

    val model = try {
      Model(ensureModelUnpacked().absolutePath)
    } catch (e: Exception) {
      Log.w(TAG, "vosk model load failed", e)
      return false
    }

    val minBuf = AudioRecord.getMinBufferSize(
      SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
    )
    if (minBuf <= 0) {
      Log.w(TAG, "AudioRecord min buffer invalido=$minBuf")
      model.close()
      return false
    }
    val bufSize = maxOf(minBuf, SAMPLE_RATE)
    val audio = AudioRecord(
      MediaRecorder.AudioSource.VOICE_RECOGNITION,
      SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufSize,
    )
    if (audio.state != AudioRecord.STATE_INITIALIZED) {
      Log.w(TAG, "AudioRecord nao inicializou (mic ocupado?)")
      audio.release()
      model.close()
      return false
    }

    running = true
    audio.startRecording()
    worker = thread(name = "vosk-wake") {
      val recognizer = Recognizer(model, SAMPLE_RATE.toFloat())
      val buffer = ShortArray(bufSize)
      try {
        while (running) {
          val n = audio.read(buffer, 0, buffer.size)
          if (n > 0) {
            if (!running) break
            val done = recognizer.acceptWaveForm(buffer, n)
            val text = if (done) textOf(recognizer.getResult(), "text") else textOf(recognizer.getPartialResult(), "partial")
            if (text.isNotBlank()) {
              val cmd = VoiceCommandParser.parse(text)
              if (cmd != null) {
                Log.i(TAG, "vosk wake matched -> $cmd")
                onCommand(cmd)
              }
            }
          } else if (n < 0) {
            Log.w(TAG, "AudioRecord.read error=$n, encerrando engine")
            diedOnError = true
            break
          }
        }
      } finally {
        recognizer.close()
        model.close()
        runCatching { audio.stop() }.onFailure { e -> Log.w(TAG, "audioRecord stop failed", e) }
        audio.release()
        if (diedOnError) {
          running = false
          onDied?.invoke()
        }
      }
    }
    return true
  }

  override fun stop() {
    running = false
    worker?.join(THREAD_JOIN_MS)
    worker = null
  }

  override fun isAlive(): Boolean = running && worker?.isAlive == true

  private fun textOf(json: String, key: String): String =
    runCatching { JSONObject(json).optString(key) }.getOrDefault("")

  private fun ensureModelUnpacked(): File {
    val dest = File(context.filesDir, MODEL_DIR)
    if (File(dest, MODEL_SENTINEL).exists()) return dest
    dest.mkdirs()
    copyAssetDir(MODEL_DIR, dest)
    return dest
  }

  private fun copyAssetDir(assetPath: String, dest: File) {
    val children = context.assets.list(assetPath) ?: emptyArray()
    if (children.isEmpty()) {
      context.assets.open(assetPath).use { input ->
        dest.outputStream().use { input.copyTo(it) }
      }
      return
    }
    dest.mkdirs()
    for (child in children) {
      copyAssetDir("$assetPath/$child", File(dest, child))
    }
  }

  companion object {
    private const val TAG = "RaroVoice"
    private const val SAMPLE_RATE = 16000
    private const val MODEL_DIR = "vosk-model-small-pt-0.3"
    private const val MODEL_SENTINEL = "final.mdl"
    private const val THREAD_JOIN_MS = 2000L

    fun isModelAvailable(context: Context): Boolean =
      runCatching { context.assets.list(MODEL_DIR)?.contains(MODEL_SENTINEL) == true }
        .getOrDefault(false)
  }
}
