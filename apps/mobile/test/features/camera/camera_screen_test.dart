import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/hud_overlay.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/lens_switcher.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/rec_button.dart';
import 'package:raro_mobile/features/replay/application/replay_flutter_api_provider.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository.dart';
import 'package:raro_mobile/features/replay/data/replay_buffer_repository_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/paywall/presentation/widgets/subscription_popup.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';

class _FakeSubscriptionStore implements SubscriptionStore {
  _FakeSubscriptionStore(this._stored);

  final SubscriptionState _stored;

  @override
  Future<SubscriptionState> load() async => _stored;

  @override
  Future<void> save(SubscriptionState state) async {}
}

class _FakeSettingsStore implements SettingsStore {
  RecordingSettings _stored = const RecordingSettings();

  @override
  Future<RecordingSettings> load() async => _stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    _stored = settings;
  }
}

class _MockCameraRepository extends Mock implements CameraRepository {}

class _MockReplayRepository extends Mock implements ReplayBufferRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );
    registerFallbackValue(LensType.wide);
    registerFallbackValue(
      CameraConfig(
        lens: LensType.wide,
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
      ),
    );
  });

  _MockCameraRepository buildRepo({
    bool hasPermission = false,
    String startRecordingSessionId = 'sess-1',
  }) {
    final repo = _MockCameraRepository();
    when(repo.discoverCapabilities).thenAnswer(
      (_) async => CameraCapabilities(
        availableLenses: [LensType.ultraWide, LensType.wide],
        supportedFormats: [
          FormatCapability(
            resolution: Resolution.fhd1080,
            fps: Fps.fps30,
            requiresPhysicalLens: false,
          ),
          FormatCapability(
            resolution: Resolution.fhd1080,
            fps: Fps.fps60,
            requiresPhysicalLens: false,
          ),
        ],
      ),
    );
    when(repo.hasPermission).thenAnswer((_) async => hasPermission);
    when(repo.stopSession).thenAnswer((_) async {});
    when(
      () => repo.startRecording(any()),
    ).thenAnswer((_) async => startRecordingSessionId);
    when(repo.stopRecording).thenAnswer((_) async {});
    return repo;
  }

  Widget harness({
    VoidCallback? onGallery,
    VoidCallback? onSettings,
    VoidCallback? onSeePlans,
    SubscriptionState? subscription,
    CameraRepository? repository,
    ReplayBufferRepository? replayRepository,
    Stream<ReplayResult>? replayEvents,
  }) {
    return ProviderScope(
      overrides: [
        cameraRepositoryProvider.overrideWithValue(repository ?? buildRepo()),
        settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
        if (replayRepository != null)
          replayBufferRepositoryProvider.overrideWithValue(replayRepository),
        if (replayEvents != null)
          replayEventsProvider.overrideWithValue(replayEvents),
        if (subscription != null)
          subscriptionStoreProvider.overrideWithValue(
            _FakeSubscriptionStore(subscription),
          ),
      ],
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: CameraScreen(
          onGallery: onGallery ?? () {},
          onSettings: onSettings ?? () {},
          onSeePlans: onSeePlans ?? () {},
        ),
      ),
    );
  }

  group('CameraScreen', () {
    testWidgets('renderiza wordmark RARO e o REC button', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text('RARO'), findsOneWidget);
      expect(find.byType(RecButton), findsOneWidget);
    });

    testWidgets('mostra hint central quando idle', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text('DIGA “RARO” PARA GRAVAR'), findsOneWidget);
    });

    testWidgets('mostra HUD com resolução/fps/lens (ASCII x como #hudLens)', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text('1080p · 60FPS · 1x'), findsOneWidget);
    });

    testWidgets('mostra a buffer pill Raro Replay 15s', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.text('Raro Replay 15s'), findsOneWidget);
    });

    testWidgets('tap no REC exibe o indicador de gravação', (tester) async {
      final repo = buildRepo(startRecordingSessionId: 'sess-rec');
      await tester.pumpWidget(harness(repository: repo));
      await tester.pump();

      expect(find.byType(RecIndicator), findsNothing);
      await tester.tap(find.byType(RecButton));
      await tester.pump();
      await tester.pump();

      expect(find.byType(RecIndicator), findsOneWidget);
      verify(() => repo.startRecording(any())).called(1);
    });

    testWidgets('tap no REC inclui o pré-roll quando o buffer está armado', (
      tester,
    ) async {
      final repo = buildRepo(hasPermission: true);
      when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
      final replayRepo = _MockReplayRepository();
      when(() => replayRepo.enable(any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        harness(repository: repo, replayRepository: replayRepo),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(RecButton));
      await tester.pump();

      final opts =
          verify(() => repo.startRecording(captureAny())).captured.single
              as RecordingOptions;
      expect(opts.includeReplayPreroll, isTrue);
    });

    testWidgets(
      'tap no REC NÃO inclui pré-roll quando o buffer não está armado',
      (tester) async {
        final repo = buildRepo(hasPermission: false);
        await tester.pumpWidget(harness(repository: repo));
        await tester.pump();

        await tester.tap(find.byType(RecButton));
        await tester.pump();

        final opts =
            verify(() => repo.startRecording(captureAny())).captured.single
                as RecordingOptions;
        expect(opts.includeReplayPreroll, isFalse);
      },
    );

    testWidgets('tap na lente 0.5× atualiza o provider', (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraRepositoryProvider.overrideWithValue(buildRepo()),
            settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
          ],
          child: MaterialApp(
            theme: buildRaroDarkTheme(),
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return CameraScreen(
                  onGallery: () {},
                  onSettings: () {},
                  onSeePlans: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LensSwitcher), findsOneWidget);
      await tester.tap(find.text('0.5×'));
      await tester.pump();
      expect(capturedRef.read(cameraShellProvider).lens, LensType.ultraWide);
    });

    testWidgets('tap na lente chama switchLens nativo quando ready', (
      tester,
    ) async {
      final repo = buildRepo(hasPermission: true);
      when(() => repo.startSession(any(), any())).thenAnswer((_) async {});
      when(() => repo.switchLens(any())).thenAnswer((_) async {});
      await tester.pumpWidget(harness(repository: repo));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('0.5×'));
      await tester.pump();

      verify(() => repo.switchLens(LensType.ultraWide)).called(1);
    });

    testWidgets('tap na lente NÃO chama switchLens nativo quando não ready', (
      tester,
    ) async {
      final repo = buildRepo();
      when(() => repo.switchLens(any())).thenAnswer((_) async {});
      await tester.pumpWidget(harness(repository: repo));
      await tester.pump();

      await tester.tap(find.text('0.5×'));
      await tester.pump();

      verifyNever(() => repo.switchLens(any()));
    });

    testWidgets('tap em gallery e settings dispara callbacks', (tester) async {
      var gallery = false;
      var settings = false;
      await tester.pumpWidget(
        harness(
          onGallery: () => gallery = true,
          onSettings: () => settings = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('camera_gallery_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('camera_settings_button')));
      await tester.pump();

      expect(gallery, isTrue);
      expect(settings, isTrue);
    });

    testWidgets('popup M01 aparece após 450ms quando não-assinado', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(subscription: const SubscriptionState.initial()),
      );
      await tester.pump();
      expect(find.byType(SubscriptionPopup), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SubscriptionPopup), findsOneWidget);
    });

    testWidgets('popup M01 NÃO aparece quando assinado', (tester) async {
      await tester.pumpWidget(
        harness(
          subscription: SubscriptionState(
            isSubscribed: true,
            trialStartedAt: DateTime(2026, 6),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SubscriptionPopup), findsNothing);
    });

    testWidgets('CTA do popup dispara onSeePlans', (tester) async {
      var seePlans = false;
      await tester.pumpWidget(
        harness(
          subscription: const SubscriptionState.initial(),
          onSeePlans: () => seePlans = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Assinar agora'));
      await tester.pump();
      expect(seePlans, isTrue);
    });

    testWidgets('"Talvez depois" fecha o popup', (tester) async {
      await tester.pumpWidget(
        harness(subscription: const SubscriptionState.initial()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SubscriptionPopup), findsOneWidget);

      await tester.tap(find.text('Talvez depois'));
      await tester.pump();
      expect(find.byType(SubscriptionPopup), findsNothing);
    });
  });
}
