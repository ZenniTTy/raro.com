import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

part 'camera_shell_state.freezed.dart';

@freezed
abstract class CameraShellState with _$CameraShellState {
  const factory CameraShellState({
    required bool recording,
    required LensType lens,
  }) = _CameraShellState;

  const CameraShellState._();

  String get lensLabel => lens == LensType.ultraWide ? '0.5×' : '1×';

  String get hudLensLabel => lens == LensType.ultraWide ? '0.5x' : '1x';
}
