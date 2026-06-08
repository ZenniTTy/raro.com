import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/features/voice/application/voice_controller.dart';
import 'package:raro_mobile/features/voice/application/voice_flutter_api_provider.dart';
import 'package:raro_mobile/features/voice/data/voice_repository.dart';
import 'package:raro_mobile/features/voice/data/voice_repository_provider.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_shared/raro_shared.dart';

class _MockVoiceRepository extends Mock implements VoiceRepository {}

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
  late StreamController<WakeCommand> wakeEvents;
  late StreamController<VoiceListeningState> stateEvents;

  setUp(() {
    wakeEvents = StreamController<WakeCommand>.broadcast();
    stateEvents = StreamController<VoiceListeningState>.broadcast();
  });

  tearDown(() async {
    await wakeEvents.close();
    await stateEvents.close();
  });

  _MockVoiceRepository buildRepo({bool available = true}) {
    final repo = _MockVoiceRepository();
    when(repo.isAvailable).thenAnswer((_) async => available);
    when(repo.startListening).thenAnswer((_) async {});
    when(repo.stopListening).thenAnswer((_) async {});
    return repo;
  }

  ProviderContainer makeContainer(
    VoiceRepository repo, {
    ControlMode controlMode = ControlMode.voice,
  }) {
    final container = ProviderContainer(
      overrides: [
        voiceRepositoryProvider.overrideWithValue(repo),
        settingsStoreProvider.overrideWithValue(
          _FakeSettingsStore(RecordingSettings(controlMode: controlMode)),
        ),
        voiceWakeEventsProvider.overrideWithValue(wakeEvents.stream),
        voiceStateEventsProvider.overrideWithValue(stateEvents.stream),
      ],
    );
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      voiceControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(keepAlive.close);
    return container;
  }

  test('engine gated off: controlMode=voice + isAvailable=true settles to '
      'VoiceIdle, startListening NOT called', () async {
    final repo = buildRepo();
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    verifyNever(repo.startListening);
    verify(repo.stopListening).called(1);
    expect(container.read(voiceControllerProvider), const VoiceIdle());
  });

  test('controlMode=volume: stopListening called, state VoiceIdle, '
      'startListening NOT called', () async {
    final repo = buildRepo();
    final container = makeContainer(repo, controlMode: ControlMode.volume);

    await container.read(settingsControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    verify(repo.stopListening).called(1);
    verifyNever(repo.startListening);
    expect(container.read(voiceControllerProvider), const VoiceIdle());
  });

  test('engine gated off: controlMode=voice + isAvailable=false settles to '
      'VoiceIdle, startListening NOT called', () async {
    final repo = buildRepo(available: false);
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    verifyNever(repo.startListening);
    expect(container.read(voiceControllerProvider), const VoiceIdle());
  });

  test('onWakeDetected(start) dispatches WakeCommand.start to the registered '
      'trigger', () async {
    final repo = buildRepo();
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    WakeCommand? captured;
    container
        .read(voiceRecordingTriggerProvider.notifier)
        .register((cmd) => captured = cmd);

    wakeEvents.add(WakeCommand.start);
    await Future<void>.delayed(Duration.zero);

    expect(captured, WakeCommand.start);
  });

  test('voiceStateEvents paused → VoicePaused', () async {
    final repo = buildRepo();
    final container = makeContainer(repo);

    await container.read(settingsControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    stateEvents.add(VoiceListeningState.paused);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(voiceControllerProvider), const VoicePaused());
  });
}
