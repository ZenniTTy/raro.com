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
  private var model: Model? = null
  private var recognizer: Recognizer? = null
  private var record: AudioRecord? = null
  @Volatile private var running = false
  private var worker: Thread? = null

  @SuppressLint("MissingPermission")
  override fun start(onCommand: (WakeCommand) -> Unit) {
    if (running) return

    val m = try {
      Model(ensureModelUnpacked().absolutePath)
    } catch (e: Exception) {
      Log.w(TAG, "vosk model load failed", e)
      return
    }
    model = m
    val rec = Recognizer(m, SAMPLE_RATE.toFloat())
    recognizer = rec

    val minBuf = AudioRecord.getMinBufferSize(
      SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
    )
    if (minBuf <= 0) {
      Log.w(TAG, "AudioRecord min buffer invalido=$minBuf")
      releaseVosk()
      return
    }
    val bufSize = maxOf(minBuf, SAMPLE_RATE)
    val audio = AudioRecord(
      MediaRecorder.AudioSource.VOICE_RECOGNITION,
      SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufSize,
    )
    if (audio.state != AudioRecord.STATE_INITIALIZED) {
      Log.w(TAG, "AudioRecord nao inicializou (mic ocupado?)")
      audio.release()
      releaseVosk()
      return
    }
    record = audio
    running = true
    audio.startRecording()

    worker = thread(name = "vosk-wake") {
      val buffer = ShortArray(bufSize)
      while (running) {
        val n = audio.read(buffer, 0, buffer.size)
        if (n > 0) {
          val done = rec.acceptWaveForm(buffer, n)
          val text = if (done) textOf(rec.getResult(), "text") else textOf(rec.getPartialResult(), "partial")
          if (text.isNotBlank()) {
            val cmd = VoiceCommandParser.parse(text)
            if (cmd != null) {
              Log.i(TAG, "vosk wake matched -> $cmd")
              onCommand(cmd)
            }
          }
        }
      }
    }
  }

  override fun stop() {
    running = false
    record?.let { runCatching { it.stop() }.onFailure { e -> Log.w(TAG, "audioRecord stop failed", e) } }
    worker?.join(THREAD_JOIN_MS)
    worker = null
    record?.release()
    record = null
    releaseVosk()
  }

  private fun releaseVosk() {
    recognizer?.close()
    recognizer = null
    model?.close()
    model = null
  }

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

  private companion object {
    const val TAG = "RaroVoice"
    const val SAMPLE_RATE = 16000
    const val MODEL_DIR = "vosk-model-small-pt-0.3"
    const val MODEL_SENTINEL = "final.mdl"
    const val THREAD_JOIN_MS = 1500L
  }
}
