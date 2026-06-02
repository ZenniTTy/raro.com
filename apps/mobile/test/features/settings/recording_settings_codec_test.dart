import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/settings/data/recording_settings_codec.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';

void main() {
  group('RecordingSettingsCodec', () {
    test(
      'encode produz pares chave→nome-do-enum nas StorageKeys canônicas',
      () {
        const settings = RecordingSettings(
          resolution: Resolution.hd720,
          fps: Fps.fps30,
          bufferDuration: BufferDuration.seconds15,
          controlMode: ControlMode.volume,
          language: AppLanguage.en,
        );

        final map = RecordingSettingsCodec.encode(settings);

        expect(map[StorageKeys.preferredResolution], 'hd720');
        expect(map[StorageKeys.preferredFps], 'fps30');
        expect(map[StorageKeys.preferredBufferDuration], 'seconds15');
        expect(map[StorageKeys.preferredControlMode], 'volume');
        expect(map[StorageKeys.selectedLanguage], 'en');
      },
    );

    test('decode de mapa vazio devolve defaults', () {
      final decoded = RecordingSettingsCodec.decode(const {});

      expect(decoded, const RecordingSettings());
    });

    test('encode→decode é round-trip fiel', () {
      const settings = RecordingSettings(
        resolution: Resolution.uhd4k60,
        fps: Fps.fps30,
        bufferDuration: BufferDuration.seconds15,
        controlMode: ControlMode.volume,
        language: AppLanguage.es,
      );

      final restored = RecordingSettingsCodec.decode(
        RecordingSettingsCodec.encode(settings),
      );

      expect(restored, settings);
    });

    test('valor inválido cai no default sem crashar (resiliência)', () {
      final decoded = RecordingSettingsCodec.decode(const {
        'raro.camera.resolution': 'lixo_invalido',
        'raro.camera.fps': 'fps30',
      });

      expect(decoded.resolution, Resolution.fullHd1080);
      expect(decoded.fps, Fps.fps30);
    });
  });
}
