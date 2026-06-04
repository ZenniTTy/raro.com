import 'package:raro_mobile/features/settings/data/recording_settings_codec.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsStore {
  Future<RecordingSettings> load();
  Future<void> save(RecordingSettings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  const SharedPreferencesSettingsStore();

  @override
  Future<RecordingSettings> load() async {
    final prefs = SharedPreferencesAsync();
    final raw = <String, String?>{
      for (final key in RecordingSettingsCodec.keys)
        key: await prefs.getString(key),
    };
    return RecordingSettingsCodec.decode(raw);
  }

  @override
  Future<void> save(RecordingSettings settings) async {
    final prefs = SharedPreferencesAsync();
    final encoded = RecordingSettingsCodec.encode(settings);
    for (final entry in encoded.entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }
}
