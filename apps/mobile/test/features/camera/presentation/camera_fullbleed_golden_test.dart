import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository_provider.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/features/voice/application/voice_flutter_api_provider.dart';
import 'package:raro_mobile/features/voice/data/voice_repository.dart';
import 'package:raro_mobile/features/voice/data/voice_repository_provider.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class _FakeSettingsStore implements SettingsStore {
  @override
  Future<RecordingSettings> load() async => const RecordingSettings();

  @override
  Future<void> save(RecordingSettings settings) async {}
}

class _FakeSubscriptionStore implements SubscriptionStore {
  @override
  Future<SubscriptionState> load() async => const SubscriptionState.initial();

  @override
  Future<void> save(SubscriptionState state) async {}
}

class _StubVoiceRepository implements VoiceRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}
}

class _MockCameraRepository extends Mock implements CameraRepository {}

class _MockReplayRepository extends Mock implements ReplayBufferRepository {}

_MockReplayRepository _buildReplayRepo() {
  final repo = _MockReplayRepository();
  when(() => repo.enable(any())).thenAnswer((_) async {});
  when(repo.disable).thenAnswer((_) async {});
  return repo;
}

_MockCameraRepository _buildRepo() {
  final repo = _MockCameraRepository();
  when(repo.discoverCapabilities).thenAnswer(
    (_) async => CameraCapabilities(
      availableLenses: [LensType.ultraWide, LensType.wide],
      supportedFormats: [
        FormatCapability(
          resolution: Resolution.fhd1080,
          fps: Fps.fps60,
          requiresPhysicalLens: false,
        ),
      ],
    ),
  );
  when(repo.hasPermission).thenAnswer((_) async => true);
  when(repo.stopSession).thenAnswer((_) async {});
  return repo;
}

void _noop() {}

Widget _cameraUnderInsets({bool fakeSubscription = false}) {
  return SizedBox(
    width: 400,
    height: 860,
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 860),
        viewPadding: EdgeInsets.only(top: 40, bottom: 48),
        padding: EdgeInsets.only(top: 40, bottom: 48),
      ),
      child: ProviderScope(
        overrides: [
          cameraRepositoryProvider.overrideWithValue(_buildRepo()),
          settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
          voiceRepositoryProvider.overrideWithValue(_StubVoiceRepository()),
          voiceWakeEventsProvider.overrideWithValue(const Stream.empty()),
          voiceStateEventsProvider.overrideWithValue(const Stream.empty()),
          replayBufferRepositoryProvider.overrideWithValue(_buildReplayRepo()),
          if (fakeSubscription)
            subscriptionStoreProvider.overrideWithValue(
              _FakeSubscriptionStore(),
            ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: const CameraScreen(
            onGallery: _noop,
            onSettings: _noop,
            onSeePlans: _noop,
          ),
        ),
      ),
    ),
  );
}

void main() {
  goldenTest(
    'camera_fullbleed',
    fileName: 'camera_fullbleed',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'ready with android insets',
          child: _cameraUnderInsets(),
        ),
      ],
    ),
  );

  goldenTest(
    'camera_fullbleed_popup',
    fileName: 'camera_fullbleed_popup',
    // 2 pumps de 300ms disparam o timer de 450ms do popup de assinatura.
    pumpBeforeTest: pumpNTimes(2, const Duration(milliseconds: 300)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'subscription popup inteiro sobre o full-bleed',
          child: _cameraUnderInsets(fakeSubscription: true),
        ),
      ],
    ),
  );
}
