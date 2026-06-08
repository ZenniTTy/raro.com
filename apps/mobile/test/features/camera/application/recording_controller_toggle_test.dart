import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/application/recording_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
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

  late StreamController<RecordingResult> events;

  ProviderContainer makeContainer(CameraRepository repo) {
    final container = ProviderContainer(
      overrides: [
        cameraRepositoryProvider.overrideWithValue(repo),
        recordingEventsProvider.overrideWithValue(events.stream),
      ],
    );
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      recordingControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(keepAlive.close);
    return container;
  }

  setUp(() {
    events = StreamController<RecordingResult>.broadcast();
  });

  tearDown(() => events.close());

  RecordingOptions opts() => RecordingOptions(
    resolution: Resolution.fhd1080,
    fps: Fps.fps60,
    codec: 'h265',
  );

  test(
    'toggle a partir de idle inicia gravação (startRecording chamado)',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 't-1');
      final container = makeContainer(repo);

      await container
          .read(recordingControllerProvider.notifier)
          .toggle(options: opts());

      final captured =
          verify(() => repo.startRecording(captureAny())).captured.single
              as RecordingOptions;
      expect(captured.fps, Fps.fps60);
      expect(
        container.read(recordingControllerProvider),
        isA<RecordingStarting>(),
      );
    },
  );

  test(
    'toggle a partir de active para a gravação (stopRecording chamado)',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 't-2');
      when(repo.stopRecording).thenAnswer((_) async {});
      final container = makeContainer(repo);
      final notifier = container.read(recordingControllerProvider.notifier);

      await notifier.toggle(options: opts());
      events.add(const RecordingResult.started(sessionId: 't-2'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(recordingControllerProvider),
        isA<RecordingActive>(),
      );

      await notifier.toggle(options: opts());
      verify(repo.stopRecording).called(1);
      expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
    },
  );

  test(
    'toggle passa as options recebidas para startRecording (pré-roll flag preservado)',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 't-3');
      final container = makeContainer(repo);

      final withPreroll = RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps60,
        codec: 'h265',
        includeReplayPreroll: true,
      );
      await container
          .read(recordingControllerProvider.notifier)
          .toggle(options: withPreroll);

      final captured =
          verify(() => repo.startRecording(captureAny())).captured.single
              as RecordingOptions;
      expect(captured.includeReplayPreroll, isTrue);
    },
  );
}
