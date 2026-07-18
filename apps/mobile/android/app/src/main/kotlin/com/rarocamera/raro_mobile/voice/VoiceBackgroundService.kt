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
    startAsForeground()
    val e = VoskWakeEngine(applicationContext)
    engine = e
    e.start { command -> commandListener?.invoke(command) }
    Log.i(TAG, "voice background service started")
    return START_STICKY
  }

  private fun startAsForeground() {
    val notification: Notification = NotificationCompat.Builder(this, ensureChannel())
      .setContentTitle("Raro")
      .setContentText("Escuta em segundo plano ativa")
      .setSmallIcon(applicationInfo.icon)
      .setOngoing(true)
      .build()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
    } else {
      startForeground(NOTIF_ID, notification)
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

    fun start(context: Context) {
      context.startForegroundService(Intent(context, VoiceBackgroundService::class.java))
    }

    fun stop(context: Context) {
      context.stopService(Intent(context, VoiceBackgroundService::class.java))
    }
  }
}
