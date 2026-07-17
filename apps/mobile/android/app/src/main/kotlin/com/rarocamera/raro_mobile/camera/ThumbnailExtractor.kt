package com.rarocamera.raro_mobile.camera

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream

object ThumbnailExtractor {
  fun extractFirstFrameJpeg(videoPath: String): String {
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(videoPath)
      val frame = retriever.getFrameAtTime(0)
        ?: throw CameraNativeException.FormatUnsupported
      val video = File(videoPath)
      val out = File(video.parentFile, "${video.nameWithoutExtension}.jpg")
      try {
        val ok = FileOutputStream(out).use {
          frame.compress(Bitmap.CompressFormat.JPEG, 85, it)
        }
        if (!ok) {
          out.delete()
          throw CameraNativeException.FormatUnsupported
        }
      } finally {
        frame.recycle()
      }
      return out.absolutePath
    } finally {
      retriever.release()
    }
  }
}
