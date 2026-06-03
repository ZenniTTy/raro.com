import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';

class RecordingController {
  RecordingController({required this.repo});

  final CameraRepository repo;
  RecordingPhase _phase = const RecordingIdle();

  RecordingPhase get phase => _phase;

  Future<void> start(RecordingOptions options) async {
    if (_phase is RecordingActive) return;
    final sessionId = await repo.startRecording(options);
    _phase = RecordingActive(sessionId: sessionId, startedAt: DateTime.now());
  }

  Future<void> stop() async {
    if (_phase is! RecordingActive) return;
    await repo.stopRecording();
    _phase = const RecordingIdle();
  }
}
