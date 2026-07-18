package com.rarocamera.raro_mobile.voice

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.rarocamera.raro_mobile.generated.voice.WakeCommand

class VoiceBackgroundService : Service() {
  private var engine: WakeEngine? = null

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (engine != null) return START_STICKY

    if (!startAsForeground()) {
      Log.w(TAG, "startForeground recusado, encerrando servico")
      onUnavailable?.invoke()
      stopSelf()
      return START_NOT_STICKY
    }

    val e = VoskWakeEngine(applicationContext)
    val started = e.start { command -> commandListener?.invoke(command) }
    if (!started) {
      Log.w(TAG, "vosk engine nao iniciou, encerrando servico")
      onUnavailable?.invoke()
      stopSelf()
      return START_NOT_STICKY
    }
    engine = e
    onListening?.invoke()
    Log.i(TAG, "voice background service started")
    return START_STICKY
  }

  private fun startAsForeground(): Boolean {
    val notification: Notification = NotificationCompat.Builder(this, ensureChannel())
      .setContentTitle("Raro")
      .setContentText("Escuta em segundo plano ativa")
      .setSmallIcon(applicationInfo.icon)
      .setOngoing(true)
      .build()
    return try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
      } else {
        startForeground(NOTIF_ID, notification)
      }
      true
    } catch (e: Exception) {
      Log.w(TAG, "startForeground falhou (janela while-in-use?)", e)
      false
    }
  }

  private fun ensureChannel(): String {
    val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val channel = NotificationChannel(
      CHANNEL_ID, "Escuta de voz", NotificationManager.IMPORTANCE_LOW,
    )
    mgr.createNotificationChannel(channel)
    return CHANNEL_ID
  }

  override fun onDestroy() {
    engine?.stop()
    engine = null
    Log.i(TAG, "voice background service stopped")
    super.onDestroy()
  }

  companion object {
    private const val TAG = "RaroVoice"
    private const val CHANNEL_ID = "raro_voice_bg"
    private const val NOTIF_ID = 4243

    @Volatile var commandListener: ((WakeCommand) -> Unit)? = null
    @Volatile var onUnavailable: (() -> Unit)? = null
    @Volatile var onListening: (() -> Unit)? = null

    fun start(context: Context): Boolean =
      try {
        context.startForegroundService(Intent(context, VoiceBackgroundService::class.java))
        true
      } catch (e: Exception) {
        Log.w(TAG, "startForegroundService recusado (janela while-in-use?)", e)
        false
      }

    fun stop(context: Context) {
      context.stopService(Intent(context, VoiceBackgroundService::class.java))
    }
  }
}
