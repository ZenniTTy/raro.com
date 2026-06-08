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
      switch (result) {
        case RecordingStarted(:final sessionId):
          state = RecordingActive(
            sessionId: sessionId,
            startedAt: DateTime.now(),
          );
        case RecordingFinished():
        case RecordingFailed():
          state = const RecordingIdle();
      }
    });
    ref.onDispose(subscription.cancel);
    return const RecordingIdle();
  }

  Future<void> start(RecordingOptions options) async {
    if (state is RecordingStarting || state is RecordingActive) return;
    state = const RecordingStarting();
    final repo = ref.read(cameraRepositoryProvider);
    try {
      await repo.startRecording(options);
    } on Object {
      state = const RecordingIdle();
      rethrow;
    }
  }

  Future<void> stop() async {
    if (state is! RecordingActive && state is! RecordingStarting) return;
    final repo = ref.read(cameraRepositoryProvider);
    try {
      await repo.stopRecording();
    } finally {
      state = const RecordingIdle();
    }
  }

  Future<void> toggle({required RecordingOptions options}) async {
    final current = state;
    if (current is RecordingActive || current is RecordingStarting) {
      await stop();
    } else {
      await start(options);
    }
  }
}
