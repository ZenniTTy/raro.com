package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.TypedValue
import android.view.Choreographer
import android.view.View

class FocusRingView(context: Context) : View(context) {
  private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    color = Color.WHITE
    strokeWidth = dp(1.5f)
  }
  private val radiusPx = dp(28f)
  private val choreographer = Choreographer.getInstance()

  private var ringScale = 1f
  private var startNanos = 0L
  private var running = false

  private val frameCallback = object : Choreographer.FrameCallback {
    override fun doFrame(frameTimeNanos: Long) {
      if (!running) return
      if (startNanos == 0L) startNanos = frameTimeNanos
      val elapsed = (frameTimeNanos - startNanos) / 1_000_000f
      if (elapsed >= TOTAL_MS) {
        finish()
        return
      }
      applyFrame(elapsed)
      invalidate()
      choreographer.postFrameCallback(this)
    }
  }

  init {
    visibility = INVISIBLE
  }

  override fun onDraw(canvas: Canvas) {
    canvas.drawCircle(width / 2f, height / 2f, radiusPx * ringScale, ringPaint)
  }

  fun show(centerX: Float, centerY: Float) {
    val side = (radiusPx * SCALE_IN_FROM + ringPaint.strokeWidth) * 2f
    layoutParams?.let {
      it.width = side.toInt()
      it.height = side.toInt()
      layoutParams = it
    }
    x = centerX - side / 2f
    y = centerY - side / 2f

    choreographer.removeFrameCallback(frameCallback)
    startNanos = 0L
    running = true
    applyFrame(0f)
    visibility = VISIBLE
    choreographer.postFrameCallback(frameCallback)
  }

  fun stop() {
    running = false
    choreographer.removeFrameCallback(frameCallback)
    visibility = INVISIBLE
  }

  override fun onDetachedFromWindow() {
    stop()
    super.onDetachedFromWindow()
  }

  private fun applyFrame(elapsed: Float) {
    ringScale = when {
      elapsed < SCALE_IN_MS -> {
        val t = decelerate(elapsed / SCALE_IN_MS)
        SCALE_IN_FROM + (1f - SCALE_IN_FROM) * t
      }
      else -> 1f
    }
    alpha = when {
      elapsed < SCALE_IN_MS -> maxOf(elapsed / SCALE_IN_MS, MIN_VISIBLE_ALPHA)
      elapsed < HOLD_UNTIL_MS -> 1f
      else -> 1f - (elapsed - HOLD_UNTIL_MS) / FADE_MS
    }.coerceIn(0f, 1f)
  }

  private fun finish() {
    running = false
    alpha = 0f
    visibility = INVISIBLE
  }

  private fun decelerate(t: Float): Float = 1f - (1f - t) * (1f - t)

  private fun dp(value: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

  companion object {
    private const val SCALE_IN_FROM = 1.35f
    private const val SCALE_IN_MS = 130f
    private const val HOLD_UNTIL_MS = 480f
    private const val FADE_MS = 220f
    private const val TOTAL_MS = HOLD_UNTIL_MS + FADE_MS
    private const val MIN_VISIBLE_ALPHA = 0.35f
  }
}
