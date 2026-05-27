import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/analytics/firebase_analytics_provider.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_analytics_listener.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_shared/raro_shared.dart' hide Resolution, Fps;

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

class _MockRepo extends Mock implements CameraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
  });

  _MockRepo makeRepo() {
    final repo = _MockRepo();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    when(repo.stopSession).thenAnswer((_) async {});
    return repo;
  }

  _MockAnalytics makeAnalytics() {
    final analytics = _MockAnalytics();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    return analytics;
  }

  test('emits cameraStarted on ready', () async {
    final analytics = makeAnalytics();
    final repo = makeRepo();
    when(() => repo.startSession(any(), any())).thenAnswer((_) async {});

    final c = ProviderContainer(
      overrides: [
        cameraRepositoryProvider.overrideWithValue(repo),
        firebaseAnalyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(c.dispose);

    c.listen(cameraAnalyticsListenerProvider, (_, _) {});
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

    verify(
      () => analytics.logEvent(
        name: AnalyticsEvents.cameraStarted,
        parameters: any(named: 'parameters'),
      ),
    ).called(1);
  });

  test('emits cameraError on error state', () async {
    final analytics = makeAnalytics();
    final repo = makeRepo();
    when(() => repo.startSession(any(), any())).thenThrow(Exception('fail'));

    final c = ProviderContainer(
      overrides: [
        cameraRepositoryProvider.overrideWithValue(repo),
        firebaseAnalyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(c.dispose);

    c.listen(cameraAnalyticsListenerProvider, (_, _) {});
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

    verify(
      () => analytics.logEvent(
        name: AnalyticsEvents.cameraError,
        parameters: any(named: 'parameters'),
      ),
    ).called(1);
  });
}
