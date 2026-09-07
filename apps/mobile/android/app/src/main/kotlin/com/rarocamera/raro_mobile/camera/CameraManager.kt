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
import com.rarocamera.raro_mobile.generated.camera.CameraErrorCode
import com.rarocamera.raro_mobile.generated.camera.RecordingOptions
import com.rarocamera.raro_mobile.generated.camera.Resolution
import com.rarocamera.raro_mobile.replay.ReplayBuffer
import com.rarocamera.raro_mobile.replay.ReplaySegment
import java.io.File
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
  private val mainExecutor = ContextCompat.getMainExecutor(context)
  private val recordingController = RecordingController(context, mainExecutor)
  private val replayBuffer = ReplayBuffer(context, mainExecutor)
  private var pendingPreroll: List<ReplaySegment>? = null
  private var pendingStart = false
  private var queuedStop = false

  var onLensSwitched: ((LensType) -> Unit)? = null
  var onFocusResult: ((FocusPoint, Boolean) -> Unit)? = null
  var onReplaySaved: ((String, Long) -> Unit)? = null
  var onReplayFailed: ((String, String?) -> Unit)? = null

  init {
    replayBuffer.onSaved = { file, durationMs ->
      onReplaySaved?.invoke(file.absolutePath, durationMs)
    }
    replayBuffer.onFailed = { code, message ->
      onReplayFailed?.invoke(code, message)
    }
  }

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
      replayBuffer.releaseCapture()
      p.unbindAll()
      val selector = CameraLensDiscovery.selectorFor(p, config.lens)
      val pv = buildPreview(config.resolution, config.fps)
      pv.setSurfaceProvider(sp)
      val vc = buildVideoCapture(config.resolution, config.fps)
      camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
      preview = pv
      videoCapture = vc
      currentConfig = config
      replayBuffer.attach(vc)
    } catch (e: CameraNativeException) {
      throw e
    } catch (e: Throwable) {
      Log.w(TAG, "bindIfReady failed", e)
      throw CameraNativeException.SessionFailed(e.message ?: e.javaClass.simpleName)
    }
  }

  fun stopSession() {
    replayBuffer.disable()
    provider?.unbindAll()
    preview = null
    camera = null
    videoCapture = null
    currentConfig = null
    pendingConfig = null
    pendingPreroll = null
    pendingStart = false
    queuedStop = false
  }

  fun switchLens(lens: LensType) {
    val p = providerNow()
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    replayBuffer.releaseCapture()
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, lens)
    val pv = buildPreview(cfg.resolution, cfg.fps)
    surfaceProvider?.let(pv::setSurfaceProvider)
    val vc = buildVideoCapture(cfg.resolution, cfg.fps)
    camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
    preview = pv
    videoCapture = vc
    currentConfig = cfg.copy(lens = lens)
    replayBuffer.attach(vc)
    onLensSwitched?.invoke(lens)
  }

  fun setFormat(resolution: Resolution, fps: Fps) {
    val cfg = currentConfig ?: throw CameraNativeException.NotRunning
    val p = providerNow()
    replayBuffer.releaseCapture()
    p.unbindAll()
    val selector = CameraLensDiscovery.selectorFor(p, cfg.lens)
    val pv = buildPreview(resolution, fps)
    surfaceProvider?.let(pv::setSurfaceProvider)
    val vc = buildVideoCapture(resolution, fps)
    camera = p.bindToLifecycle(lifecycleOwner, selector, pv, vc)
    preview = pv
    videoCapture = vc
    currentConfig = cfg.copy(resolution = resolution, fps = fps)
    replayBuffer.attach(vc)
  }

  fun enableReplayBuffer(seconds: Int) {
    replayBuffer.enable(seconds)
    videoCapture?.let { replayBuffer.attach(it) }
  }

  fun disableReplayBuffer() {
    replayBuffer.disable()
  }

  fun pauseReplayBuffer() {
    replayBuffer.pauseEncoder()
  }

  fun resumeReplayBuffer() {
    videoCapture?.let { replayBuffer.attach(it) }
    replayBuffer.resumeEncoder()
  }

  fun saveReplay() {
    if (videoCapture == null) throw CameraNativeException.NotRunning
    replayBuffer.saveStandalone()
  }

  fun startRecording(
    options: RecordingOptions,
    callbacks: RecordingController.RecordingCallbacks,
  ): String {
    val vc = videoCapture ?: throw CameraNativeException.NotRunning
    val sessionId = UUID.randomUUID().toString()
    val includePreroll = options.includeReplayPreroll
    pendingStart = true
    queuedStop = false
    replayBuffer.freeze { snapshot ->
      when (decideRecordingAfterFreeze(pendingStart, queuedStop)) {
        RecordingFreezeDecision.RESUME_ONLY -> {
          replayBuffer.resume()
          return@freeze
        }
        RecordingFreezeDecision.ABORT_QUEUED_STOP -> {
          queuedStop = false
          pendingStart = false
          pendingPreroll = null
          replayBuffer.resume()
          callbacks.onFailed(
            CameraErrorCode.SESSION_FAILED,
            "recording cancelled before start",
          )
          return@freeze
        }
        RecordingFreezeDecision.START -> Unit
      }
      pendingPreroll = if (includePreroll && snapshot.isNotEmpty()) snapshot else null
      try {
        recordingController.start(vc, sessionId, wrapRecordingCallbacks(sessionId, callbacks))
        pendingStart = false
        queuedStop = false
      } catch (e: SecurityException) {
        pendingStart = false
        pendingPreroll = null
        replayBuffer.resume()
        callbacks.onFailed(CameraErrorCode.PERMISSION_DENIED, e.message)
      } catch (e: Throwable) {
        pendingStart = false
        pendingPreroll = null
        replayBuffer.resume()
        callbacks.onFailed(CameraErrorCode.SESSION_FAILED, e.message)
      }
    }
    return sessionId
  }

  fun stopRecording() {
    if (pendingStart) {
      queuedStop = true
      return
    }
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

  private fun wrapRecordingCallbacks(
    sessionId: String,
    callbacks: RecordingController.RecordingCallbacks,
  ): RecordingController.RecordingCallbacks {
    return object : RecordingController.RecordingCallbacks {
      override fun onStarted(sessionId: String) {
        callbacks.onStarted(sessionId)
      }

      override fun onFinished(path: String, durationMs: Long) {
        val preroll = pendingPreroll
        pendingPreroll = null
        if (preroll == null || preroll.isEmpty()) {
          replayBuffer.resume()
          callbacks.onFinished(path, durationMs)
          return
        }
        finishWithPreroll(sessionId, File(path), durationMs, preroll, callbacks)
      }

      override fun onFailed(code: CameraErrorCode, message: String?) {
        pendingPreroll = null
        replayBuffer.resume()
        callbacks.onFailed(code, message)
      }
    }
  }

  private fun finishWithPreroll(
    sessionId: String,
    g1: File,
    g1DurationMs: Long,
    preroll: List<ReplaySegment>,
    callbacks: RecordingController.RecordingCallbacks,
  ) {
    val parent = g1.parentFile ?: context.cacheDir
    val staged = File(parent, "raro_${sessionId}_g1.mp4")
    if (g1.exists() && !g1.renameTo(staged)) {
      Log.w(TAG, "preroll export failed — could not stage recording; delivering recording-only clip")
      replayBuffer.resume()
      callbacks.onFinished(g1.absolutePath, g1DurationMs)
      return
    }
    val combined = File(parent, raroTempName(sessionId))
    replayBuffer.concatPreroll(preroll, staged, combined) { result ->
      result.fold(
        onSuccess = { durationMs ->
          if (staged.exists()) staged.delete()
          replayBuffer.resume()
          Log.i(TAG, "preroll concat ok durationMs=$durationMs")
          callbacks.onFinished(combined.absolutePath, durationMs)
        },
        onFailure = { error ->
          Log.w(TAG, "preroll export failed — falling back to recording-only clip", error)
          if (combined.exists()) combined.delete()
          if (staged.exists() && !g1.exists()) {
            staged.renameTo(g1)
          }
          replayBuffer.resume()
          val fallback = if (g1.exists()) g1 else staged
          callbacks.onFinished(fallback.absolutePath, g1DurationMs)
        },
      )
    }
  }

  private fun providerNow(): ProcessCameraProvider {
    val existing = provider
    if (existing != null) return existing
    val fresh = ProcessCameraProvider.getInstance(context).get()
    provider = fresh
    return fresh
  }

  @OptIn(ExperimentalCamera2Interop::class)
  private fun buildVideoCapture(resolution: Resolution, fps: Fps): VideoCapture<Recorder> {
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
    val fpsHz = requestedFps(fps)
    val builder = VideoCapture.Builder(recorder)
      .setTargetFrameRate(Range(fpsHz, fpsHz))
    Camera2Interop.Extender(builder).setCaptureRequestOption(
      CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
      Range(fpsHz, fpsHz),
    )
    return builder.build()
  }

  @OptIn(ExperimentalCamera2Interop::class)
  private fun buildPreview(resolution: Resolution, fps: Fps): Preview {
    val size = when (resolution) {
      Resolution.HD720 -> Size(1280, 720)
      Resolution.FHD1080 -> Size(1920, 1080)
      Resolution.UHD4K -> Size(3840, 2160)
    }
    val fpsHz = requestedFps(fps)
    val selector = ResolutionSelector.Builder()
      .setResolutionStrategy(
        ResolutionStrategy(size, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER)
      )
      .build()
    val builder = Preview.Builder()
      .setResolutionSelector(selector)
      .setTargetFrameRate(Range(fpsHz, fpsHz))
    Camera2Interop.Extender(builder).setCaptureRequestOption(
      CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
      Range(fpsHz, fpsHz)
    )
    return builder.build()
  }

  private fun requestedFps(fps: Fps): Int = if (fps == Fps.FPS60) 60 else 30
}
