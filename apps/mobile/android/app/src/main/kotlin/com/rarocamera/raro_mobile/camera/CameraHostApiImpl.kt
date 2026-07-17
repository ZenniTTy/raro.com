package com.rarocamera.raro_mobile.camera

import android.os.Handler
import android.os.Looper
import com.rarocamera.raro_mobile.generated.camera.CameraCapabilities
import com.rarocamera.raro_mobile.generated.camera.CameraConfig
import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode
import com.rarocamera.raro_mobile.generated.camera.CameraFlutterApi
import com.rarocamera.raro_mobile.generated.camera.CameraHostApi
import com.rarocamera.raro_mobile.generated.camera.FlutterError
import com.rarocamera.raro_mobile.generated.camera.FocusPoint
import com.rarocamera.raro_mobile.generated.camera.Fps
import com.rarocamera.raro_mobile.generated.camera.LensType
import com.rarocamera.raro_mobile.generated.camera.RecordingOptions
import com.rarocamera.raro_mobile.generated.camera.Resolution

class CameraHostApiImpl(
  private val manager: CameraManager,
  private val flutterApi: CameraFlutterApi,
) : CameraHostApi {
  private val main = Handler(Looper.getMainLooper())

  init {
    manager.onLensSwitched = { lens ->
      main.post { flutterApi.onLensSwitched(lens) {} }
    }
  }

  private fun toFlutterError(e: Throwable): FlutterError {
    if (e is CameraNativeException) {
      return FlutterError(code = e.symbolicCode(), message = e.message, details = null)
    }
    return FlutterError(code = "sessionFailed", message = e.message ?: e.javaClass.simpleName, details = null)
  }

  override fun discoverCapabilities(callback: (Result<CameraCapabilities>) -> Unit) {
    try {
      callback(Result.success(manager.discoverCapabilities()))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun startSession(textureId: Long, config: CameraConfig, callback: (Result<Unit>) -> Unit) {
    try {
      manager.startSession(config)
      main.post { flutterApi.onSessionStarted(config) {} }
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun stopSession(callback: (Result<Unit>) -> Unit) {
    try {
      manager.stopSession()
      main.post { flutterApi.onSessionStopped {} }
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun switchLens(lens: LensType, callback: (Result<Unit>) -> Unit) {
    try {
      manager.switchLens(lens)
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun setFormat(resolution: Resolution, fps: Fps, callback: (Result<Unit>) -> Unit) {
    try {
      manager.setFormat(resolution, fps)
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun focusAt(point: FocusPoint, callback: (Result<Unit>) -> Unit) {
    try {
      manager.focusAt(point) { locked ->
        main.post { flutterApi.onFocusChanged(point, locked) {} }
      }
      callback(Result.success(Unit))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun startRecording(options: RecordingOptions): String {
    try {
      return manager.startRecording(
        options,
        object : RecordingController.RecordingCallbacks {
          override fun onStarted(sessionId: String) {
            main.post { flutterApi.onRecordingStarted(sessionId) {} }
          }

          override fun onFinished(path: String, durationMs: Long) {
            main.post { flutterApi.onRecordingFinished(path, durationMs) {} }
          }

          override fun onFailed(code: CameraErrorCode, message: String?) {
            main.post { flutterApi.onRecordingFailed(code, message) {} }
          }
        },
      )
    } catch (e: Throwable) {
      throw toFlutterError(e)
    }
  }

  override fun stopRecording() {
    try {
      manager.stopRecording()
    } catch (e: Throwable) {
      throw toFlutterError(e)
    }
  }

  override fun generateThumbnail(videoPath: String, callback: (Result<String>) -> Unit) {
    try {
      callback(Result.success(ThumbnailExtractor.extractFirstFrameJpeg(videoPath)))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun requestPermission(callback: (Result<Boolean>) -> Unit) {
    try {
      callback(Result.success(manager.requestPermission()))
    } catch (e: Throwable) {
      callback(Result.failure(toFlutterError(e)))
    }
  }

  override fun hasPermission(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(manager.hasPermission()))
  }
}
