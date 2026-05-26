import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/pigeon_camera_repository.dart';

class _MockHostApi extends Mock implements CameraHostApi {}

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
  });

  test('discoverCapabilities delegates to host api', () async {
    final api = _MockHostApi();
    when(api.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedResolutions: [Resolution.fhd1080],
        supportedFps: [Fps.fps30],
      ),
    );
    final repo = PigeonCameraRepository(api);
    final caps = await repo.discoverCapabilities();
    expect(caps.availableLenses, [LensType.wide]);
  });

  test('startSession forwards textureId + config', () async {
    final api = _MockHostApi();
    when(() => api.startSession(any(), any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.startSession(
      42,
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
    verify(() => api.startSession(42, any())).called(1);
  });

  test('focusAt forwards normalized point', () async {
    final api = _MockHostApi();
    when(() => api.focusAt(any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.focusAt(FocusPoint(x: 0.5, y: 0.5));
    verify(() => api.focusAt(any())).called(1);
  });
}
