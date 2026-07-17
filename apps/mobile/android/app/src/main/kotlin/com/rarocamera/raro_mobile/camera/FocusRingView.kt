package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.TypedValue
import android.view.View

class FocusRingView(context: Context) : View(context) {
  private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    color = Color.WHITE
    strokeWidth = dp(1.5f)
  }
  private val radiusPx = dp(32f)

  init {
    visibility = INVISIBLE
  }

  override fun onDraw(canvas: Canvas) {
    canvas.drawCircle(width / 2f, height / 2f, radiusPx, ringPaint)
  }

  fun show(centerX: Float, centerY: Float) {
    val side = (radiusPx + ringPaint.strokeWidth) * 2f
    layoutParams?.let {
      it.width = side.toInt()
      it.height = side.toInt()
      layoutParams = it
    }
    x = centerX - side / 2f
    y = centerY - side / 2f

    animate().cancel()
    alpha = 1f
    scaleX = 1.4f
    scaleY = 1.4f
    visibility = VISIBLE
    animate()
      .scaleX(1f)
      .scaleY(1f)
      .setDuration(DURATION_MS)
      .withEndAction {
        animate()
          .alpha(0f)
          .setDuration(FADE_MS)
          .withEndAction { visibility = INVISIBLE }
          .start()
      }
      .start()
  }

  private fun dp(value: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

  companion object {
    private const val DURATION_MS = 960L
    private const val FADE_MS = 240L
  }
}
