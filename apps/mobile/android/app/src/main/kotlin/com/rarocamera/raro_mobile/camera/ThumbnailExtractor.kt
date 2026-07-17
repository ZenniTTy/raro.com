package com.rarocamera.raro_mobile.camera

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream

object ThumbnailExtractor {
  fun extractFirstFrameJpeg(context: Context, videoPath: String): String {
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(videoPath)
      val frame = retriever.getFrameAtTime(0)
        ?: throw CameraNativeException.FormatUnsupported
      val stem = File(videoPath).nameWithoutExtension
      val out = File(context.cacheDir, "$stem.jpg")
      FileOutputStream(out).use { frame.compress(Bitmap.CompressFormat.JPEG, 85, it) }
      return out.absolutePath
    } finally {
      retriever.release()
    }
  }
}
