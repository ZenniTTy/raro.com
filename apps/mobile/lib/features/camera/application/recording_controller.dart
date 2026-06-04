import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_controller.g.dart';

@riverpod
class RecordingController extends _$RecordingController {
  @override
  RecordingPhase build() {
    final events = ref.watch(recordingEventsProvider);
    final subscription = events.listen((result) {
      if (result is RecordingFinished || result is RecordingFailed) {
        state = const RecordingIdle();
      }
    });
    ref.onDispose(subscription.cancel);
    return const RecordingIdle();
  }

  Future<void> start(RecordingOptions options) async {
    if (state is RecordingActive) return;
    final repo = ref.read(cameraRepositoryProvider);
    final sessionId = await repo.startRecording(options);
    state = RecordingActive(sessionId: sessionId, startedAt: DateTime.now());
  }

  Future<void> stop() async {
    if (state is! RecordingActive) return;
    final repo = ref.read(cameraRepositoryProvider);
    try {
      await repo.stopRecording();
    } finally {
      state = const RecordingIdle();
    }
  }
}
