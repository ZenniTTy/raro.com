import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';

part 'camera_state.freezed.dart';

@freezed
sealed class CameraState with _$CameraState {
  const factory CameraState.idle({required CameraCapabilities capabilities}) =
      CameraStateIdle;
  const factory CameraState.initializing() = CameraStateInitializing;
  const factory CameraState.ready({
    required CameraSettings activeSettings,
    FocusPoint? lastFocusPoint,
  }) = CameraStateReady;
  const factory CameraState.error({
    required CameraErrorCode code,
    String? message,
  }) = CameraStateError;
}
