import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_shared/raro_shared.dart';

class _FakeSettingsStore implements SettingsStore {
  RecordingSettings _stored;

  _FakeSettingsStore([this._stored = const RecordingSettings()]);

  int saveCount = 0;

  @override
  Future<RecordingSettings> load() async => _stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    _stored = settings;
    saveCount++;
  }
}

void main() {
  ProviderContainer makeContainer(SettingsStore store) {
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsController', () {
    test('build carrega settings persistidos do store', () async {
      final store = _FakeSettingsStore(
        const RecordingSettings(resolution: Resolution.uhd4k60),
      );
      final container = makeContainer(store);

      final loaded = await container.read(settingsControllerProvider.future);

      expect(loaded.resolution, Resolution.uhd4k60);
    });

    test('setResolution atualiza state e persiste no store', () async {
      final store = _FakeSettingsStore();
      final container = makeContainer(store);
      await container.read(settingsControllerProvider.future);

      await container
          .read(settingsControllerProvider.notifier)
          .setResolution(Resolution.hd720);

      final state = container.read(settingsControllerProvider).requireValue;
      expect(state.resolution, Resolution.hd720);
      expect(store.saveCount, 1);
      expect((await store.load()).resolution, Resolution.hd720);
    });

    test(
      'setResolution(uhd4k60) coage fps para 60 (estado consistente)',
      () async {
        final store = _FakeSettingsStore(
          const RecordingSettings(fps: Fps.fps30),
        );
        final container = makeContainer(store);
        await container.read(settingsControllerProvider.future);

        await container
            .read(settingsControllerProvider.notifier)
            .setResolution(Resolution.uhd4k60);

        final state = container.read(settingsControllerProvider).requireValue;
        expect(state.resolution, Resolution.uhd4k60);
        expect(state.fps, Fps.fps60);
        expect((await store.load()).fps, Fps.fps60);
      },
    );

    test('setResolution não-4K60 preserva o fps escolhido', () async {
      final store = _FakeSettingsStore(const RecordingSettings(fps: Fps.fps30));
      final container = makeContainer(store);
      await container.read(settingsControllerProvider.future);

      await container
          .read(settingsControllerProvider.notifier)
          .setResolution(Resolution.uhd4k);

      expect(
        container.read(settingsControllerProvider).requireValue.fps,
        Fps.fps30,
      );
    });

    test('setControlMode persiste o modo de controle', () async {
      final store = _FakeSettingsStore();
      final container = makeContainer(store);
      await container.read(settingsControllerProvider.future);

      await container
          .read(settingsControllerProvider.notifier)
          .setControlMode(ControlMode.volume);

      expect(
        container.read(settingsControllerProvider).requireValue.controlMode,
        ControlMode.volume,
      );
      expect((await store.load()).controlMode, ControlMode.volume);
    });

    test('setLanguage persiste o idioma sem trocar textos do app', () async {
      final store = _FakeSettingsStore();
      final container = makeContainer(store);
      await container.read(settingsControllerProvider.future);

      await container
          .read(settingsControllerProvider.notifier)
          .setLanguage(AppLanguage.es);

      expect((await store.load()).language, AppLanguage.es);
    });

    test('setBufferDuration e setFps persistem', () async {
      final store = _FakeSettingsStore();
      final container = makeContainer(store);
      await container.read(settingsControllerProvider.future);
      final notifier = container.read(settingsControllerProvider.notifier);

      await notifier.setBufferDuration(BufferDuration.seconds15);
      await notifier.setFps(Fps.fps30);

      final stored = await store.load();
      expect(stored.bufferDuration, BufferDuration.seconds15);
      expect(stored.fps, Fps.fps30);
    });
  });
}
