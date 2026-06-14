import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';

class _MockRepo extends Mock implements CameraRepository {}

_MockRepo _makeRepo() {
  final repo = _MockRepo();
  when(repo.discoverCapabilities).thenAnswer(
    (_) async => CameraCapabilities(
      availableLenses: [LensType.wide],
      supportedFormats: [
        FormatCapability(
          resolution: Resolution.fhd1080,
          fps: Fps.fps30,
          requiresPhysicalLens: false,
        ),
      ],
    ),
  );
  when(repo.stopSession).thenAnswer((_) async {});
  return repo;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    registerFallbackValue(FocusPoint(x: 0, y: 0));
    registerFallbackValue(LensType.wide);
    registerFallbackValue(Resolution.fhd1080);
    registerFallbackValue(Fps.fps30);
  });

  ProviderContainer makeContainer(CameraRepository repo) => ProviderContainer(
    overrides: [cameraRepositoryProvider.overrideWithValue(repo)],
  );

  test('build returns idle with capabilities', () async {
    final repo = _makeRepo();
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    final state = await c.read(cameraControllerProvider.future);
    expect(state, isA<CameraStateIdle>());
  });

  test('start transitions to ready', () async {
    final repo = _makeRepo();
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .start(
          textureId: 1,
          settings: const CameraSettings(
            lens: LensType.wide,
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
          ),
        );
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateReady>());
  });

  test('start emits error when session fails', () async {
    final repo = _makeRepo();
    when(
      () => repo.startSession(any(), any()),
    ).thenThrow(Exception('CameraErrorCode.permissionDenied'));
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .start(
          textureId: 1,
          settings: const CameraSettings(
            lens: LensType.wide,
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
          ),
        );
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateError>());
  });

  test('start maps PlatformException code to CameraErrorCode', () async {
    final repo = _makeRepo();
    when(() => repo.startSession(any(), any())).thenThrow(
      PlatformException(code: 'permissionDenied', message: 'denied by user'),
    );
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .start(
          textureId: 1,
          settings: const CameraSettings(
            lens: LensType.wide,
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
          ),
        );
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateError>());
    final err = state as CameraStateError;
    expect(err.code, CameraErrorCode.permissionDenied);
    expect(err.message, contains('denied by user'));
  });

  test('switchLens is a no-op on state when not Ready', () async {
    final repo = _makeRepo();
    when(() => repo.switchLens(any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .switchLens(LensType.ultraWide);
    verify(() => repo.switchLens(LensType.ultraWide)).called(1);
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateIdle>());
  });

  test('setFormat is a no-op on state when not Ready', () async {
    final repo = _makeRepo();
    when(() => repo.setFormat(any(), any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .setFormat(Resolution.uhd4k, Fps.fps60);
    verify(() => repo.setFormat(Resolution.uhd4k, Fps.fps60)).called(1);
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateIdle>());
  });

  test('focusAt is a no-op on state when not Ready', () async {
    final repo = _makeRepo();
    when(() => repo.focusAt(any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c.read(cameraControllerProvider.notifier).focusAt(0.5, 0.5);
    verify(() => repo.focusAt(any())).called(1);
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateIdle>());
  });

  test('stop transitions to Idle and re-discovers capabilities', () async {
    final repo = _makeRepo();
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .start(
          textureId: 1,
          settings: const CameraSettings(
            lens: LensType.wide,
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
          ),
        );
    await c.read(cameraControllerProvider.notifier).stop();
    verify(() => repo.stopSession()).called(greaterThanOrEqualTo(1));
    verify(() => repo.discoverCapabilities()).called(2);
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateIdle>());
  });

  test('focusAt updates lastFocusPoint when ready', () async {
    final repo = _makeRepo();
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
    when(() => repo.focusAt(any())).thenAnswer((_) async {});
    final c = makeContainer(repo);
    addTearDown(c.dispose);
    await c.read(cameraControllerProvider.future);
    await c
        .read(cameraControllerProvider.notifier)
        .start(
          textureId: 1,
          settings: const CameraSettings(
            lens: LensType.wide,
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
          ),
        );
    await c.read(cameraControllerProvider.notifier).focusAt(0.5, 0.5);
    final state = c.read(cameraControllerProvider).requireValue;
    expect(state, isA<CameraStateReady>());
    final ready = state as CameraStateReady;
    expect(ready.lastFocusPoint?.x, 0.5);
  });
}
