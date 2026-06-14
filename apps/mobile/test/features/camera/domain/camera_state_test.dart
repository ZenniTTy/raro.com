import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';

void main() {
  group('CameraSettings', () {
    test('toConfig maps to pigeon CameraConfig', () {
      const s = CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps60,
      );
      final c = s.toConfig();
      expect(c.lens, LensType.wide);
      expect(c.resolution, Resolution.fhd1080);
      expect(c.fps, Fps.fps60);
    });

    test('copyWith overrides single field', () {
      const s = CameraSettings(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      );
      final r = s.copyWith(lens: LensType.ultraWide);
      expect(r.lens, LensType.ultraWide);
      expect(r.resolution, Resolution.fhd1080);
      expect(r.fps, Fps.fps30);
    });
  });

  group('CameraState', () {
    test('idle has capabilities, no error', () {
      final caps = CameraCapabilities(
        availableLenses: [LensType.wide],
        supportedFormats: [
          FormatCapability(
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
            requiresPhysicalLens: false,
          ),
        ],
      );
      final s = CameraState.idle(capabilities: caps);
      final lenses = switch (s) {
        CameraStateIdle(:final capabilities) => capabilities.availableLenses,
        _ => null,
      };
      expect(lenses, [LensType.wide]);
    });

    test('error carries code and message', () {
      const s = CameraState.error(
        code: CameraErrorCode.permissionDenied,
        message: 'denied',
      );
      final result = switch (s) {
        CameraStateError(:final code, :final message) => '$code|$message',
        _ => null,
      };
      expect(result, '${CameraErrorCode.permissionDenied}|denied');
    });
  });
}
