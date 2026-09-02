package com.rarocamera.raro_mobile

import com.rarocamera.raro_mobile.camera.CameraHostApiImpl
import com.rarocamera.raro_mobile.camera.CameraManager
import com.rarocamera.raro_mobile.camera.CameraPlatformViewFactory
import com.rarocamera.raro_mobile.generated.camera.CameraFlutterApi
import com.rarocamera.raro_mobile.generated.camera.CameraHostApi
import com.rarocamera.raro_mobile.generated.voice.VoiceFlutterApi
import com.rarocamera.raro_mobile.generated.voice.VoiceHostApi
import com.rarocamera.raro_mobile.voice.VoiceHostApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var voiceHostApi: VoiceHostApiImpl? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    val manager = CameraManager(applicationContext, this)
    val flutterApi = CameraFlutterApi(messenger)
    val hostApi = CameraHostApiImpl(manager, flutterApi)
    CameraHostApi.setUp(messenger, hostApi)
    flutterEngine
      .platformViewsController
      .registry
      .registerViewFactory(
        "com.rarocamera/camera_preview",
        CameraPlatformViewFactory(manager),
      )

    val voice = VoiceHostApiImpl(applicationContext, VoiceFlutterApi(messenger))
    voiceHostApi = voice
    VoiceHostApi.setUp(messenger, voice)
  }

  override fun onDestroy() {
    voiceHostApi?.dispose()
    voiceHostApi = null
    super.onDestroy()
  }
}
