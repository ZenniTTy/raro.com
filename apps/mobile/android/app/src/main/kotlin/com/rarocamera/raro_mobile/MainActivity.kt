package com.rarocamera.raro_mobile

import com.rarocamera.raro_mobile.camera.CameraHostApiImpl
import com.rarocamera.raro_mobile.camera.CameraManager
import com.rarocamera.raro_mobile.camera.CameraPlatformViewFactory
import com.rarocamera.raro_mobile.generated.camera.CameraFlutterApi
import com.rarocamera.raro_mobile.generated.camera.CameraHostApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    val manager = CameraManager(applicationContext, this)
    val flutterApi = CameraFlutterApi(messenger)
    val hostApi = CameraHostApiImpl(applicationContext, manager, flutterApi)
    CameraHostApi.setUp(messenger, hostApi)
    flutterEngine
      .platformViewsController
      .registry
      .registerViewFactory(
        "com.rarocamera/camera_preview",
        CameraPlatformViewFactory(manager),
      )
  }
}
