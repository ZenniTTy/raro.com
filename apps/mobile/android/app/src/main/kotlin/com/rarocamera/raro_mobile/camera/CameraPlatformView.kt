package com.rarocamera.raro_mobile.camera

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
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

  private val focusRing = FocusRingView(context)

  private val container: FrameLayout = FrameLayout(context).apply {
    addView(
      previewView,
      FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT,
      ),
    )
    addView(focusRing, FrameLayout.LayoutParams(0, 0))
  }

  private val gestureDetector = GestureDetector(
    context,
    object : GestureDetector.SimpleOnGestureListener() {
      override fun onDown(e: MotionEvent): Boolean = true

      override fun onSingleTapUp(e: MotionEvent): Boolean {
        handleTap(e.x, e.y)
        return true
      }
    },
  )

  init {
    manager.surfaceProvider = previewView.surfaceProvider
    installTapListener()
  }

  @SuppressLint("ClickableViewAccessibility")
  private fun installTapListener() {
    previewView.setOnTouchListener { _, event ->
      gestureDetector.onTouchEvent(event)
    }
  }

  private fun handleTap(x: Float, y: Float) {
    focusRing.show(x, y)
    val point = previewView.meteringPointFactory.createPoint(x, y)
    try {
      manager.focusAtMeteringPoint(point) { locked ->
        Log.d(TAG, "tap focus at ($x,$y) locked=$locked")
      }
    } catch (e: CameraNativeException) {
      Log.w(TAG, "tap focus ignored: ${e.message}")
    }
  }

  override fun getView(): View = container

  override fun dispose() {
    manager.surfaceProvider = null
  }

  private companion object {
    const val TAG = "RaroCamera"
  }
}
