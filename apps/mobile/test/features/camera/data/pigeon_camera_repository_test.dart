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
    registerFallbackValue(LensType.wide);
    registerFallbackValue(Resolution.fhd1080);
    registerFallbackValue(Fps.fps30);
    registerFallbackValue(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );
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
    final captured = verify(() => api.startSession(42, captureAny())).captured;
    expect(captured, hasLength(1));
    final config = captured.single as CameraConfig;
    expect(config.lens, LensType.wide);
    expect(config.resolution, Resolution.fhd1080);
    expect(config.fps, Fps.fps30);
  });

  test('focusAt forwards normalized point', () async {
    final api = _MockHostApi();
    when(() => api.focusAt(any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.focusAt(FocusPoint(x: 0.5, y: 0.5));
    verify(() => api.focusAt(any())).called(1);
  });

  test('stopSession delegates to host api', () async {
    final api = _MockHostApi();
    when(api.stopSession).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.stopSession();
    verify(api.stopSession).called(1);
  });

  test('switchLens forwards lens type', () async {
    final api = _MockHostApi();
    when(() => api.switchLens(any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.switchLens(LensType.ultraWide);
    verify(() => api.switchLens(LensType.ultraWide)).called(1);
  });

  test('setFormat forwards resolution and fps', () async {
    final api = _MockHostApi();
    when(() => api.setFormat(any(), any())).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.setFormat(Resolution.uhd4k, Fps.fps60);
    verify(() => api.setFormat(Resolution.uhd4k, Fps.fps60)).called(1);
  });

  test('requestPermission delegates to host api', () async {
    final api = _MockHostApi();
    when(api.requestPermission).thenAnswer((_) async => true);
    final repo = PigeonCameraRepository(api);
    final result = await repo.requestPermission();
    expect(result, isTrue);
    verify(api.requestPermission).called(1);
  });

  test('hasPermission delegates to host api', () async {
    final api = _MockHostApi();
    when(api.hasPermission).thenAnswer((_) async => false);
    final repo = PigeonCameraRepository(api);
    final result = await repo.hasPermission();
    expect(result, isFalse);
    verify(api.hasPermission).called(1);
  });

  test('startRecording forwards options + returns session id', () async {
    final api = _MockHostApi();
    when(() => api.startRecording(any())).thenAnswer((_) async => 'sess-1');
    final repo = PigeonCameraRepository(api);
    final id = await repo.startRecording(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps60,
        codec: 'h265',
      ),
    );
    expect(id, 'sess-1');
    final captured = verify(() => api.startRecording(captureAny())).captured;
    final opts = captured.single as RecordingOptions;
    expect(opts.resolution, Resolution.fhd1080);
    expect(opts.fps, Fps.fps60);
    expect(opts.codec, 'h265');
  });

  test('stopRecording delegates to host api', () async {
    final api = _MockHostApi();
    when(api.stopRecording).thenAnswer((_) async {});
    final repo = PigeonCameraRepository(api);
    await repo.stopRecording();
    verify(api.stopRecording).called(1);
  });
}
