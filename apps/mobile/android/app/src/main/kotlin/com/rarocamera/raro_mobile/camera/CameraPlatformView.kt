package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import io.flutter.plugin.platform.PlatformView

class CameraPlatformView(
  context: Context,
  private val manager: CameraManager,
) : PlatformView {
  private val previewView: PreviewView = PreviewView(context).apply {
    scaleType = PreviewView.ScaleType.FILL_CENTER
    implementationMode = PreviewView.ImplementationMode.COMPATIBLE
  }

  init {
    manager.surfaceProvider = previewView.surfaceProvider
  }

  override fun getView(): View = previewView

  override fun dispose() {
    manager.surfaceProvider = null
  }
}
