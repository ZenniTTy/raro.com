import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/volume_api.g.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/features/volume/application/volume_controller.dart';
import 'package:raro_mobile/features/volume/application/volume_flutter_api_provider.dart';
import 'package:raro_mobile/features/volume/data/volume_repository.dart';
import 'package:raro_mobile/features/volume/data/volume_repository_provider.dart';
import 'package:raro_shared/raro_shared.dart';

class _MockVolumeRepository extends Mock implements VolumeRepository {}

class _FakeSettingsStore implements SettingsStore {
  _FakeSettingsStore(this._stored);

  RecordingSettings _stored;

  @override
  Future<RecordingSettings> load() async => _stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    _stored = settings;
  }
}

void main() {
  late StreamController<VolumeDirection> pressEvents;

  setUp(() {
    pressEvents = StreamController<VolumeDirection>.broadcast();
  });

  tearDown(() async {
    await pressEvents.close();
  });

  _MockVolumeRepository buildRepo({bool available = true}) {
    final repo = _MockVolumeRepository();
    when(repo.isAvailable).thenAnswer((_) async => available);
    when(repo.startListening).thenAnswer((_) async {});
    when(repo.stopListening).thenAnswer((_) async {});
    return repo;
  }

  ProviderContainer makeContainer(
    VolumeRepository repo, {
    ControlMode controlMode = ControlMode.volume,
  }) {
    final container = ProviderContainer(
      overrides: [
        volumeRepositoryProvider.overrideWithValue(repo),
        settingsStoreProvider.overrideWithValue(
          _FakeSettingsStore(RecordingSettings(controlMode: controlMode)),
        ),
        volumePressEventsProvider.overrideWithValue(pressEvents.stream),
      ],
    );
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      volumeControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(keepAlive.close);
    return container;
  }

  test('attach + controlMode=volume + available → startListening', () async {
    final repo = buildRepo();
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await container.read(volumeControllerProvider.notifier).attach();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(repo.isAvailable).called(1);
    verify(repo.startListening).called(1);
    expect(container.read(volumeControllerProvider), isTrue);
  });

  test('controlMode=voice: attach does not startListening', () async {
    final repo = buildRepo();
    final container = makeContainer(repo, controlMode: ControlMode.voice);

    await container.read(settingsControllerProvider.future);
    await container.read(volumeControllerProvider.notifier).attach();
    await Future<void>.delayed(Duration.zero);

    verifyNever(repo.startListening);
    expect(container.read(volumeControllerProvider), isFalse);
  });

  test('detach → stopListening and state false', () async {
    final repo = buildRepo();
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await container.read(volumeControllerProvider.notifier).attach();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await container.read(volumeControllerProvider.notifier).detach();
    await Future<void>.delayed(Duration.zero);

    verify(repo.stopListening).called(greaterThanOrEqualTo(1));
    expect(container.read(volumeControllerProvider), isFalse);
  });

  test('unavailable platform → no startListening after attach', () async {
    final repo = buildRepo(available: false);
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await container.read(volumeControllerProvider.notifier).attach();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(repo.isAvailable).called(1);
    verifyNever(repo.startListening);
    expect(container.read(volumeControllerProvider), isFalse);
  });

  test('onVolumePressed(up) dispatches to the registered trigger', () async {
    final repo = buildRepo();
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    VolumeDirection? captured;
    container
        .read(volumeRecordingTriggerProvider.notifier)
        .register((direction) => captured = direction);

    pressEvents.add(VolumeDirection.up);
    await Future<void>.delayed(Duration.zero);

    expect(captured, VolumeDirection.up);
  });
}
