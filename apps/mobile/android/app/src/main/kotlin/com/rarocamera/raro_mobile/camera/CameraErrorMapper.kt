package com.rarocamera.raro_mobile.camera

import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode

sealed class CameraNativeException(message: String? = null) : Exception(message) {
  object PermissionDenied : CameraNativeException()
  object DeviceUnavailable : CameraNativeException()
  object LensUnavailable : CameraNativeException()
  object FormatUnsupported : CameraNativeException()
  class SessionFailed(msg: String) : CameraNativeException(msg)
  object AlreadyRunning : CameraNativeException()
  object NotRunning : CameraNativeException()
}

fun CameraNativeException.toCode(): CameraErrorCode = when (this) {
  is CameraNativeException.PermissionDenied -> CameraErrorCode.PERMISSION_DENIED
  is CameraNativeException.DeviceUnavailable -> CameraErrorCode.DEVICE_UNAVAILABLE
  is CameraNativeException.LensUnavailable -> CameraErrorCode.LENS_UNAVAILABLE
  is CameraNativeException.FormatUnsupported -> CameraErrorCode.FORMAT_UNSUPPORTED
  is CameraNativeException.SessionFailed -> CameraErrorCode.SESSION_FAILED
  is CameraNativeException.AlreadyRunning -> CameraErrorCode.ALREADY_RUNNING
  is CameraNativeException.NotRunning -> CameraErrorCode.NOT_RUNNING
}

fun CameraNativeException.symbolicCode(): String = when (this) {
  is CameraNativeException.PermissionDenied -> "permissionDenied"
  is CameraNativeException.DeviceUnavailable -> "deviceUnavailable"
  is CameraNativeException.LensUnavailable -> "lensUnavailable"
  is CameraNativeException.FormatUnsupported -> "formatUnsupported"
  is CameraNativeException.SessionFailed -> "sessionFailed"
  is CameraNativeException.AlreadyRunning -> "alreadyRunning"
  is CameraNativeException.NotRunning -> "notRunning"
}
