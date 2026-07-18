import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';

void main() {
  group('RecordingSettings', () {
    test('defaults: 1080p, 60fps, buffer 30s, voz, idioma do sistema', () {
      const settings = RecordingSettings();

      expect(settings.resolution, Resolution.fullHd1080);
      expect(settings.fps, Fps.fps60);
      expect(settings.bufferDuration, BufferDuration.seconds30);
      expect(settings.controlMode, ControlMode.voice);
      expect(settings.language, isNull);
    });

    test('copyWith troca apenas o campo informado', () {
      const settings = RecordingSettings();

      final updated = settings.copyWith(resolution: Resolution.uhd4k);

      expect(updated.resolution, Resolution.uhd4k);
      expect(updated.fps, settings.fps);
      expect(updated.controlMode, settings.controlMode);
    });

    test('value equality por campo', () {
      const a = RecordingSettings(controlMode: ControlMode.volume);
      const b = RecordingSettings(controlMode: ControlMode.volume);
      const c = RecordingSettings(controlMode: ControlMode.voice);

      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
