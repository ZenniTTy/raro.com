import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
SettingsStore settingsStore(Ref ref) => const SharedPreferencesSettingsStore();

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Future<RecordingSettings> build() {
    return ref.read(settingsStoreProvider).load();
  }

  Future<void> setResolution(Resolution resolution) => _update(
    (s) => s.copyWith(
      resolution: resolution,
      fps: resolution == Resolution.uhd4k60 ? Fps.fps60 : s.fps,
    ),
  );

  Future<void> setFps(Fps fps) => _update((s) => s.copyWith(fps: fps));

  Future<void> setBufferDuration(BufferDuration bufferDuration) =>
      _update((s) => s.copyWith(bufferDuration: bufferDuration));

  Future<void> toggleBufferDuration() => _update(
    (s) => s.copyWith(
      bufferDuration: s.bufferDuration == BufferDuration.seconds30
          ? BufferDuration.seconds15
          : BufferDuration.seconds30,
    ),
  );

  Future<void> setControlMode(ControlMode controlMode) =>
      _update((s) => s.copyWith(controlMode: controlMode));

  Future<void> setLanguage(AppLanguage language) =>
      _update((s) => s.copyWith(language: language));

  Future<void> _update(
    RecordingSettings Function(RecordingSettings current) change,
  ) async {
    final current = state.requireValue;
    final updated = change(current);
    state = AsyncData(updated);
    await ref.read(settingsStoreProvider).save(updated);
  }
}
