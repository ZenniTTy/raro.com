import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/recording_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';

class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );
  });

  test(
    'start: idle → active with sessionId, calls repo.startRecording',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 's-1');
      final controller = RecordingController(repo: repo);
      await controller.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps60,
          codec: 'h265',
        ),
      );
      final phase = controller.phase;
      expect(phase, isA<RecordingActive>());
      expect((phase as RecordingActive).sessionId, 's-1');
      final opts =
          verify(() => repo.startRecording(captureAny())).captured.single
              as RecordingOptions;
      expect(opts.fps, Fps.fps60);
      expect(opts.codec, 'h265');
    },
  );

  test('stop: active → calls repo.stopRecording, phase back to idle', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-2');
    when(repo.stopRecording).thenAnswer((_) async {});
    final controller = RecordingController(repo: repo);
    await controller.start(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h264',
      ),
    );
    await controller.stop();
    verify(repo.stopRecording).called(1);
    expect(controller.phase, isA<RecordingIdle>());
  });

  test(
    'start: when already active is a no-op (no second startRecording)',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 's-3');
      final controller = RecordingController(repo: repo);
      await controller.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps30,
          codec: 'h265',
        ),
      );
      await controller.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps60,
          codec: 'h264',
        ),
      );
      verify(() => repo.startRecording(any())).called(1);
      expect((controller.phase as RecordingActive).sessionId, 's-3');
    },
  );

  test('stop: when idle is a no-op (no stopRecording call)', () async {
    final repo = _MockRepo();
    when(repo.stopRecording).thenAnswer((_) async {});
    final controller = RecordingController(repo: repo);
    await controller.stop();
    verifyNever(repo.stopRecording);
    expect(controller.phase, isA<RecordingIdle>());
  });
}
