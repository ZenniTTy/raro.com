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

  test('start: calls repo.startRecording but does NOT promote active on await '
      '(state is starting until native callback)', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-1');
    final container = makeContainer(repo);

    await container
        .read(recordingControllerProvider.notifier)
        .start(
          RecordingOptions(
            resolution: Resolution.fhd1080,
            fps: Fps.fps60,
            codec: 'h265',
          ),
        );

    final phase = container.read(recordingControllerProvider);
    expect(
      phase,
      isA<RecordingStarting>(),
      reason:
          'await return must not promote active — only native callback does',
    );
    final opts =
        verify(() => repo.startRecording(captureAny())).captured.single
            as RecordingOptions;
    expect(opts.fps, Fps.fps60);
    expect(opts.codec, 'h265');
  });

  test(
    'native RecordingStarted event promotes starting → active with sessionId',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 's-1');
      final container = makeContainer(repo);
      final notifier = container.read(recordingControllerProvider.notifier);

      await notifier.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps60,
          codec: 'h265',
        ),
      );

      events.add(const RecordingResult.started(sessionId: 's-1'));
      await Future<void>.delayed(Duration.zero);

      final phase = container.read(recordingControllerProvider);
      expect(phase, isA<RecordingActive>());
      expect((phase as RecordingActive).sessionId, 's-1');
    },
  );

  test('stop: active → calls repo.stopRecording, state back to idle', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-2');
    when(repo.stopRecording).thenAnswer((_) async {});
    final container = makeContainer(repo);
    final notifier = container.read(recordingControllerProvider.notifier);

    await notifier.start(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h264',
      ),
    );
    await notifier.stop();

    verify(repo.stopRecording).called(1);
    expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
  });

  test(
    'stop: when repo.stopRecording throws, state still resets to idle',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 's-3');
      when(repo.stopRecording).thenThrow(StateError('notRecording'));
      final container = makeContainer(repo);
      final notifier = container.read(recordingControllerProvider.notifier);

      await notifier.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps30,
          codec: 'h265',
        ),
      );

      await expectLater(notifier.stop(), throwsA(isA<StateError>()));
      expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
    },
  );

  test(
    'start: when already active is a no-op (no second startRecording)',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 's-4');
      final container = makeContainer(repo);
      final notifier = container.read(recordingControllerProvider.notifier);

      await notifier.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps30,
          codec: 'h265',
        ),
      );
      events.add(const RecordingResult.started(sessionId: 's-4'));
      await Future<void>.delayed(Duration.zero);
      await notifier.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps60,
          codec: 'h264',
        ),
      );

      verify(() => repo.startRecording(any())).called(1);
      expect(
        (container.read(recordingControllerProvider) as RecordingActive)
            .sessionId,
        's-4',
      );
    },
  );

  test('start: when already starting is a no-op (debounces double tap before '
      'native callback)', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-7');
    final container = makeContainer(repo);
    final notifier = container.read(recordingControllerProvider.notifier);

    await notifier.start(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );
    await notifier.start(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );

    verify(() => repo.startRecording(any())).called(1);
    expect(
      container.read(recordingControllerProvider),
      isA<RecordingStarting>(),
    );
  });

  test(
    'start: when repo.startRecording throws, state resets to idle and rethrows',
    () async {
      final repo = _MockRepo();
      when(
        () => repo.startRecording(any()),
      ).thenThrow(StateError('notRunning'));
      final container = makeContainer(repo);
      final notifier = container.read(recordingControllerProvider.notifier);

      await expectLater(
        notifier.start(
          RecordingOptions(
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
            codec: 'h265',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
    },
  );

  test('stop: when idle is a no-op (no stopRecording call)', () async {
    final repo = _MockRepo();
    when(repo.stopRecording).thenAnswer((_) async {});
    final container = makeContainer(repo);

    await container.read(recordingControllerProvider.notifier).stop();

    verifyNever(repo.stopRecording);
    expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
  });

  test(
    'native RecordingFinished event resets state to idle without stop()',
    () async {
      final repo = _MockRepo();
      when(() => repo.startRecording(any())).thenAnswer((_) async => 's-5');
      final container = makeContainer(repo);
      final notifier = container.read(recordingControllerProvider.notifier);

      await notifier.start(
        RecordingOptions(
          resolution: Resolution.fhd1080,
          fps: Fps.fps30,
          codec: 'h265',
        ),
      );
      events.add(const RecordingResult.started(sessionId: 's-5'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(recordingControllerProvider),
        isA<RecordingActive>(),
      );

      events.add(
        const RecordingResult.finished(
          path: '/tmp/raro_s-5.mov',
          durationMs: 3000,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
    },
  );

  test('native RecordingFailed event resets state to idle', () async {
    final repo = _MockRepo();
    when(() => repo.startRecording(any())).thenAnswer((_) async => 's-6');
    final container = makeContainer(repo);
    final notifier = container.read(recordingControllerProvider.notifier);

    await notifier.start(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );
    events.add(const RecordingResult.started(sessionId: 's-6'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(recordingControllerProvider), isA<RecordingActive>());

    events.add(
      const RecordingResult.failed(
        code: CameraErrorCode.sessionFailed,
        message: 'boom',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(recordingControllerProvider), isA<RecordingIdle>());
  });
}
