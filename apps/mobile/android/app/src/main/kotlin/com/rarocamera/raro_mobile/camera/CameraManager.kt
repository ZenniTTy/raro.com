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
import androidx.camera.core.MeteringPoint
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FallbackStrategy
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.VideoCapture
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.rarocamera.raro_mobile.generated.camera.CameraCapabilities
import com.rarocamera.raro_mobile.generated.camera.CameraConfig
import com.rarocamera.raro_mobile.generated.camera.FocusPoint
import com.rarocamera.raro_mobile.generated.camera.FormatCapability
import com.rarocamera.raro_mobile.generated.camera.Fps
import com.rarocamera.raro_mobile.generated.camera.LensType
import com.rarocamera.raro_mobile.generated.camera.RecordingOptions
import com.rarocamera.raro_mobile.generated.camera.Resolution
import java.util.UUID
import java.util.concurrent.ExecutionException
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
  private var pendingConfig: CameraConfig? = null
  private var videoCapture: VideoCapture<Recorder>? = null
  private val recordingController = RecordingController(context, ContextCompat.getMainExecutor(context))

  var onLensSwitched: ((LensType) -> Unit)? = null
  var onFocusResult: ((FocusPoint, Boolean) -> Unit)? = null
  var surfaceProvider: Preview.SurfaceProvider? = null
    set(value) {
      field = value
      if (value != null) {
        bindIfReady()
      } else {
        preview?.setSurfaceProvider(null)
      }
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
    if (!hasPermission()) throw CameraNativeException.PermissionDenied
    pendingConfig = config
    bindIfReady()
  }

  private fun bindIfReady() {
    val config = pendingConfig ?: return
    val sp = surfaceProvider ?: return
    val p = providerNow()
    try {
      p.unbindAll()
      val selector = CameraLensDiscovery.selectorFor(p, config.lens)
      val pv = buildPreview(config.resolution, config.fps)
      pv.setSurfaceProvider(sp)
      val vc = buildVideoCapture(config.resolution)
      camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
      preview = pv
      videoCapture = vc
      currentConfig = config
    } catch (e: CameraNativeException) {
      throw e
    } catch (e: Throwable) {
      Log.w(TAG, "bindIfReady failed", e)
      throw CameraNativeException.SessionFailed(e.message ?: e.javaClass.simpleName)
    }
  }

  fun stopSession() {
    provider?.unbindAll()
    preview = null
    camera = null
    videoCapture = null
    currentConfig = null
    pendingConfig = null
  }

  fun switchLens(lens: LensType) {
    val p = providerNow()
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, lens)
    val pv = buildPreview(cfg.resolution, cfg.fps)
    surfaceProvider?.let(pv::setSurfaceProvider)
    val vc = buildVideoCapture(cfg.resolution)
    camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
    preview = pv
    videoCapture = vc
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
    val vc = buildVideoCapture(resolution)
    camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
    preview = pv
    videoCapture = vc
    currentConfig = cfg.copy(resolution = resolution, fps = fps)
  }

  fun runReplaySpike(segments: Int, chunkSeconds: Int) {
    val vc = videoCapture ?: throw CameraNativeException.NotRunning
    com.rarocamera.raro_mobile.replay.ReplaySpikeGate(
      context,
      ContextCompat.getMainExecutor(context),
    ).run(vc, segments, chunkSeconds)
  }

  fun startRecording(
    options: RecordingOptions,
    callbacks: RecordingController.RecordingCallbacks,
  ): String {
    val vc = videoCapture ?: throw CameraNativeException.NotRunning
    if (options.includeReplayPreroll) {
      Log.w(TAG, "includeReplayPreroll ignored on Android (replay buffer is a future slice)")
    }
    val sessionId = UUID.randomUUID().toString()
    try {
      recordingController.start(vc, sessionId, callbacks)
    } catch (e: SecurityException) {
      throw CameraNativeException.PermissionDenied
    }
    return sessionId
  }

  fun stopRecording() {
    if (!recordingController.isRecording()) throw CameraNativeException.NotRunning
    recordingController.stop()
  }

  fun focusAt(point: FocusPoint, onResult: (Boolean) -> Unit) {
    val factory = SurfaceOrientedMeteringPointFactory(1f, 1f)
    val meteringPoint = factory.createPoint(point.x.toFloat(), point.y.toFloat())
    focusAtMeteringPoint(meteringPoint, onResult)
  }

  fun focusAtMeteringPoint(point: MeteringPoint, onResult: (Boolean) -> Unit) {
    val cam = camera ?: throw CameraNativeException.NotRunning
    val action = FocusMeteringAction.Builder(point)
      .setAutoCancelDuration(5, TimeUnit.SECONDS)
      .build()
    val future = cam.cameraControl.startFocusAndMetering(action)
    future.addListener({
      val ok = try {
        future.get().isFocusSuccessful
      } catch (e: ExecutionException) {
        Log.w(TAG, "focus metering failed", e)
        false
      } catch (e: InterruptedException) {
        Thread.currentThread().interrupt()
        Log.w(TAG, "focus metering interrupted", e)
        false
      }
      onResult(ok)
    }, ContextCompat.getMainExecutor(context))
  }

  private fun providerNow(): ProcessCameraProvider {
    val existing = provider
    if (existing != null) return existing
    val fresh = ProcessCameraProvider.getInstance(context).get()
    provider = fresh
    return fresh
  }

  private fun buildVideoCapture(resolution: Resolution): VideoCapture<Recorder> {
    val quality = when (resolution) {
      Resolution.UHD4K -> Quality.UHD
      Resolution.FHD1080 -> Quality.FHD
      Resolution.HD720 -> Quality.HD
    }
    val recorder = Recorder.Builder()
      .setQualitySelector(
        QualitySelector.fromOrderedList(
          listOf(quality, Quality.FHD, Quality.HD, Quality.SD),
          FallbackStrategy.lowerQualityOrHigherThan(Quality.HD),
        ),
      )
      .build()
    return VideoCapture.withOutput(recorder)
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
