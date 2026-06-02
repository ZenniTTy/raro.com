import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

part 'camera_shell_state.freezed.dart';

enum BufferDuration {
  fifteenSec(15),
  thirtySec(30);

  const BufferDuration(this.seconds);

  final int seconds;
}

@freezed
abstract class CameraShellState with _$CameraShellState {
  const factory CameraShellState({
    required bool recording,
    required LensType lens,
    required BufferDuration bufferDuration,
  }) = _CameraShellState;

  const CameraShellState._();

  String get lensLabel => lens == LensType.ultraWide ? '0.5×' : '1×';
}
