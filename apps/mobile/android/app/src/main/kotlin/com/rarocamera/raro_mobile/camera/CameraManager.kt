package com.rarocamera.raro_mobile.camera

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CaptureRequest
import android.util.Log
import android.util.Range
import android.util.Size
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.Camera
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.rarocamera.raro_mobile.generated.camera.CameraCapabilities
import com.rarocamera.raro_mobile.generated.camera.CameraConfig
import com.rarocamera.raro_mobile.generated.camera.FocusPoint
import com.rarocamera.raro_mobile.generated.camera.FormatCapability
import com.rarocamera.raro_mobile.generated.camera.Fps
import com.rarocamera.raro_mobile.generated.camera.LensType
import com.rarocamera.raro_mobile.generated.camera.Resolution
import java.util.concurrent.TimeUnit

private const val TAG = "RaroCamera"
private const val CAMERA_PERMISSION_REQUEST = 4242

class CameraManager(
  private val context: Context,
  private val lifecycleOwner: LifecycleOwner,
) {
  private var provider: ProcessCameraProvider? = null
  private var preview: Preview? = null
  private var camera: Camera? = null
  private var currentConfig: CameraConfig? = null

  var onLensSwitched: ((LensType) -> Unit)? = null
  var surfaceProvider: Preview.SurfaceProvider? = null
    set(value) {
      field = value
      preview?.let { p -> value?.let(p::setSurfaceProvider) }
    }

  fun hasPermission(): Boolean =
    ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
      PackageManager.PERMISSION_GRANTED

  fun requestPermission(): Boolean {
    if (hasPermission()) return true
    val activity = context as? Activity ?: return false
    ActivityCompat.requestPermissions(
      activity, arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST
    )
    return hasPermission()
  }

  fun discoverCapabilities(): CameraCapabilities {
    val p = providerNow()
    val lenses = CameraLensDiscovery.availableBackLenses(p)
    if (lenses.isEmpty()) throw CameraNativeException.DeviceUnavailable
    return CameraCapabilities(
      availableLenses = lenses,
      supportedFormats = buildSupportedFormats(),
    )
  }

  private fun buildSupportedFormats(): List<FormatCapability> {
    val resolutions = listOf(Resolution.HD720, Resolution.FHD1080, Resolution.UHD4K)
    val fpsOptions = listOf(Fps.FPS30, Fps.FPS60)
    return resolutions.flatMap { resolution ->
      fpsOptions.map { fps ->
        FormatCapability(
          resolution = resolution,
          fps = fps,
          requiresPhysicalLens = resolution == Resolution.UHD4K && fps == Fps.FPS60,
        )
      }
    }
  }

  fun startSession(config: CameraConfig) {
    if (preview != null) throw CameraNativeException.AlreadyRunning
    if (!hasPermission()) throw CameraNativeException.PermissionDenied
    val p = providerNow()
    try {
      val selector = CameraLensDiscovery.selectorFor(p, config.lens)
      val pv = buildPreview(config.resolution, config.fps)
      surfaceProvider?.let(pv::setSurfaceProvider)
      camera = p.bindToLifecycle(lifecycleOwner, selector, pv)
      preview = pv
      currentConfig = config
    } catch (e: CameraNativeException) {
      throw e
    } catch (e: Throwable) {
      Log.w(TAG, "startSession failed", e)
      throw CameraNativeException.SessionFailed(e.message ?: e.javaClass.simpleName)
    }
  }

  fun stopSession() {
    provider?.unbindAll()
    preview = null
    camera = null
    currentConfig = null
  }

  fun switchLens(lens: LensType) {
    val p = providerNow()
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, lens)
    val pv = buildPreview(cfg.resolution, cfg.fps)
    surfaceProvider?.let(pv::setSurfaceProvider)
    camera = p.bindToLifecycle(lifecycleOwner, selector, pv)
    preview = pv
    currentConfig = cfg.copy(lens = lens)
    onLensSwitched?.invoke(lens)
  }

  fun setFormat(resolution: Resolution, fps: Fps) {
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    val p = providerNow()
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, cfg.lens)
    val pv = buildPreview(resolution, fps)
    surfaceProvider?.let(pv::setSurfaceProvider)
    camera = p.bindToLifecycle(lifecycleOwner, selector, pv)
    preview = pv
    currentConfig = cfg.copy(resolution = resolution, fps = fps)
  }

  fun focusAt(point: FocusPoint) {
    val cam = camera ?: throw CameraNativeException.NotRunning
    val factory = SurfaceOrientedMeteringPointFactory(1f, 1f)
    val meteringPoint = factory.createPoint(point.x.toFloat(), point.y.toFloat())
    val action = FocusMeteringAction.Builder(meteringPoint)
      .setAutoCancelDuration(5, TimeUnit.SECONDS)
      .build()
    cam.cameraControl.startFocusAndMetering(action)
  }

  private fun providerNow(): ProcessCameraProvider {
    val existing = provider
    if (existing != null) return existing
    val fresh = ProcessCameraProvider.getInstance(context).get()
    provider = fresh
    return fresh
  }

  @OptIn(ExperimentalCamera2Interop::class)
  private fun buildPreview(resolution: Resolution, fps: Fps): Preview {
    val size = when (resolution) {
      Resolution.HD720 -> Size(1280, 720)
      Resolution.FHD1080 -> Size(1920, 1080)
      Resolution.UHD4K -> Size(3840, 2160)
    }
    val targetFps = if (fps == Fps.FPS60) 60 else 30
    val selector = ResolutionSelector.Builder()
      .setResolutionStrategy(
        ResolutionStrategy(size, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER)
      )
      .build()
    val builder = Preview.Builder().setResolutionSelector(selector)
    Camera2Interop.Extender(builder).setCaptureRequestOption(
      CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
      Range(targetFps, targetFps)
    )
    return builder.build()
  }
}
