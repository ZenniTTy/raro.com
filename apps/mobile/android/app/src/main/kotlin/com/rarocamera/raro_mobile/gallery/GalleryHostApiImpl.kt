package com.rarocamera.raro_mobile.gallery

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import com.rarocamera.raro_mobile.generated.gallery.FlutterError
import com.rarocamera.raro_mobile.generated.gallery.GalleryHostApi
import java.io.File
import java.io.FileInputStream
import java.util.concurrent.Executors

class GalleryHostApiImpl(
  private val context: Context,
) : GalleryHostApi {
  private val io = Executors.newSingleThreadExecutor()
  private val main = Handler(Looper.getMainLooper())

  override fun saveVideoToSystemGallery(
    videoPath: String,
    callback: (Result<Unit>) -> Unit,
  ) {
    io.execute {
      try {
        save(File(videoPath))
        finish(callback, Result.success(Unit))
      } catch (e: SecurityException) {
        Log.e(TAG, "gallery permission denied path=$videoPath", e)
        finish(
          callback,
          Result.failure(
            FlutterError(
              code = "permissionDenied",
              message = e.message,
              details = null,
            ),
          ),
        )
      } catch (e: Throwable) {
        Log.e(TAG, "gallery save failed path=$videoPath", e)
        finish(
          callback,
          Result.failure(
            FlutterError(
              code = "saveFailed",
              message = e.message ?: e.javaClass.simpleName,
              details = null,
            ),
          ),
        )
      }
    }
  }

  private fun finish(
    callback: (Result<Unit>) -> Unit,
    result: Result<Unit>,
  ) {
    main.post { callback(result) }
  }

  private fun save(source: File) {
    if (!source.exists() || !source.isFile) {
      throw IllegalArgumentException("missing video file")
    }
    val displayName = source.name.ifBlank { "raro_${System.currentTimeMillis()}.mp4" }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      saveViaMediaStore(source, displayName)
    } else {
      saveViaPublicMovies(source, displayName)
    }
  }

  private fun saveViaMediaStore(source: File, displayName: String) {
    val values =
      ContentValues().apply {
        put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
        put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
        put(
          MediaStore.Video.Media.RELATIVE_PATH,
          Environment.DIRECTORY_MOVIES + "/Raro Camera",
        )
        put(MediaStore.Video.Media.IS_PENDING, 1)
      }
    val resolver = context.contentResolver
    val uri =
      resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
        ?: throw IllegalStateException("MediaStore insert returned null")
    try {
      resolver.openOutputStream(uri)?.use { output ->
        FileInputStream(source).use { input -> input.copyTo(output) }
      } ?: throw IllegalStateException("MediaStore openOutputStream returned null")
      values.clear()
      values.put(MediaStore.Video.Media.IS_PENDING, 0)
      resolver.update(uri, values, null, null)
    } catch (e: Throwable) {
      resolver.delete(uri, null, null)
      throw e
    }
  }

  private fun saveViaPublicMovies(source: File, displayName: String) {
    val movies = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
    val album = File(movies, "Raro Camera")
    if (!album.exists() && !album.mkdirs() && !album.isDirectory) {
      throw IllegalStateException("could not create Movies/Raro Camera")
    }
    val dest = File(album, displayName)
    source.copyTo(dest, overwrite = true)
    MediaScannerConnection.scanFile(context, arrayOf(dest.absolutePath), arrayOf("video/mp4"), null)
  }

  private companion object {
    const val TAG = "RaroGallery"
  }
}
