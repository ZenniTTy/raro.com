package com.rarocamera.raro_mobile.camera

import android.hardware.camera2.CameraCharacteristics
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraInfo
import androidx.camera.core.CameraSelector
import androidx.camera.lifecycle.ProcessCameraProvider
import com.rarocamera.raro_mobile.generated.camera.LensType

object CameraLensDiscovery {
  @OptIn(ExperimentalCamera2Interop::class)
  fun availableBackLenses(provider: ProcessCameraProvider): List<LensType> {
    val backInfos = provider.availableCameraInfos.filter {
      it.lensFacing == CameraSelector.LENS_FACING_BACK
    }
    if (backInfos.isEmpty()) return emptyList()

    val focals: List<Pair<CameraInfo, Float>> = backInfos.mapNotNull { info ->
      val ch = Camera2CameraInfo.from(info)
      val f = ch.getCameraCharacteristic(
        CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS
      )?.minOrNull() ?: return@mapNotNull null
      info to f
    }
    if (focals.isEmpty()) return listOf(LensType.WIDE)

    val minFocal = focals.minOf { it.second }
    val maxFocal = focals.maxOf { it.second }
    val hasUltraWide = maxFocal > minFocal * 1.3f
    return if (hasUltraWide) listOf(LensType.ULTRA_WIDE, LensType.WIDE) else listOf(LensType.WIDE)
  }

  @OptIn(ExperimentalCamera2Interop::class)
  fun selectorFor(provider: ProcessCameraProvider, lens: LensType): CameraSelector {
    if (lens == LensType.WIDE) return CameraSelector.DEFAULT_BACK_CAMERA

    val backInfos = provider.availableCameraInfos.filter {
      it.lensFacing == CameraSelector.LENS_FACING_BACK
    }
    val ultra = backInfos.minByOrNull { info ->
      Camera2CameraInfo.from(info)
        .getCameraCharacteristic(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        ?.minOrNull() ?: Float.MAX_VALUE
    } ?: throw CameraNativeException.LensUnavailable

    return CameraSelector.Builder()
      .addCameraFilter { infos -> infos.filter { it == ultra } }
      .build()
  }
}
