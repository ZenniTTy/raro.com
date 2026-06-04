import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_shell_provider.g.dart';

@riverpod
class CameraShell extends _$CameraShell {
  @override
  CameraShellState build() => const CameraShellState(
    recording: false,
    lens: LensType.wide,
    bufferDuration: BufferDuration.fifteenSec,
  );

  void toggleRecording() {
    state = state.copyWith(recording: !state.recording);
  }

  void selectLens(LensType lens) {
    state = state.copyWith(lens: lens);
  }

  void toggleBufferDuration() {
    state = state.copyWith(
      bufferDuration: state.bufferDuration == BufferDuration.fifteenSec
          ? BufferDuration.thirtySec
          : BufferDuration.fifteenSec,
    );
  }
}
