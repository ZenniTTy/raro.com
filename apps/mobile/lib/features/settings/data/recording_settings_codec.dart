import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';

abstract final class RecordingSettingsCodec {
  static Map<String, String> encode(RecordingSettings settings) {
    return {
      StorageKeys.preferredResolution: settings.resolution.name,
      StorageKeys.preferredFps: settings.fps.name,
      StorageKeys.preferredBufferDuration: settings.bufferDuration.name,
      StorageKeys.preferredControlMode: settings.controlMode.name,
      StorageKeys.selectedLanguage: settings.language.name,
    };
  }

  static RecordingSettings decode(Map<String, String?> raw) {
    const defaults = RecordingSettings();
    return RecordingSettings(
      resolution: _byName(
        raw[StorageKeys.preferredResolution],
        Resolution.values,
        defaults.resolution,
      ),
      fps: _byName(raw[StorageKeys.preferredFps], Fps.values, defaults.fps),
      bufferDuration: _byName(
        raw[StorageKeys.preferredBufferDuration],
        BufferDuration.values,
        defaults.bufferDuration,
      ),
      controlMode: _byName(
        raw[StorageKeys.preferredControlMode],
        ControlMode.values,
        defaults.controlMode,
      ),
      language: _byName(
        raw[StorageKeys.selectedLanguage],
        AppLanguage.values,
        defaults.language,
      ),
    );
  }

  static const List<String> keys = [
    StorageKeys.preferredResolution,
    StorageKeys.preferredFps,
    StorageKeys.preferredBufferDuration,
    StorageKeys.preferredControlMode,
    StorageKeys.selectedLanguage,
  ];

  static T _byName<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}
