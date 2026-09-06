import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/app/router.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/rec_button.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/permissions/application/permission_status_provider.dart';
import 'package:raro_mobile/features/gallery/presentation/widgets/video_thumbnail.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/permissions/data/permission_gateway.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/features/voice/application/voice_flutter_api_provider.dart';
import 'package:raro_mobile/features/voice/data/voice_repository.dart';
import 'package:raro_mobile/features/voice/data/voice_repository_provider.dart';
import 'package:raro_mobile/features/volume/data/volume_repository.dart';
import 'package:raro_mobile/features/volume/data/volume_repository_provider.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../helpers/fake_billing_gateway.dart';

class _MockPermissionGateway extends Mock implements PermissionGateway {}

class _MockCameraRepository extends Mock implements CameraRepository {}

class _StubVoiceRepository implements VoiceRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}
}

class _StubVolumeRepository implements VolumeRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}
}

class _FakeSettingsStore implements SettingsStore {
  RecordingSettings stored = const RecordingSettings();

  @override
  Future<RecordingSettings> load() async => stored;

  @override
  Future<void> save(RecordingSettings settings) async {
    stored = settings;
  }
}

class _FakeSubscriptionStore implements SubscriptionStore {
  SubscriptionState stored = const SubscriptionState.initial();

  @override
  Future<SubscriptionState> load() async => stored;

  @override
  Future<void> save(SubscriptionState state) async {
    stored = state;
  }
}

class _FakeOnboardingStore implements OnboardingStore {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

void main() {
  late _MockPermissionGateway gateway;
  late _FakeSubscriptionStore subscriptionStore;
  late _MockCameraRepository cameraRepository;
  late _FakeOnboardingStore onboardingStore;
  late Directory vaultRoot;
  List<VideoEntity> seededVideos = const [];

  setUpAll(() {
    registerFallbackValue(
      RecordingOptions(
        resolution: Resolution.fhd1080,
        fps: Fps.fps30,
        codec: 'h265',
      ),
    );
  });

  setUp(() async {
    gateway = _MockPermissionGateway();
    when(gateway.cameraStatus).thenAnswer((_) async => false);
    when(gateway.microphoneStatus).thenAnswer((_) async => false);
    subscriptionStore = _FakeSubscriptionStore();
    onboardingStore = _FakeOnboardingStore();
    cameraRepository = _MockCameraRepository();
    when(cameraRepository.discoverCapabilities).thenAnswer(
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
    when(cameraRepository.hasPermission).thenAnswer((_) async => false);
    when(cameraRepository.stopSession).thenAnswer((_) async {});
    vaultRoot = await Directory.systemTemp.createTemp('router_vault_');
    seededVideos = const [];
  });

  tearDown(() {
    if (vaultRoot.existsSync()) vaultRoot.deleteSync(recursive: true);
  });

  Widget app() {
    return ProviderScope(
      overrides: [
        permissionGatewayProvider.overrideWithValue(gateway),
        settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
        subscriptionStoreProvider.overrideWithValue(subscriptionStore),
        billingGatewayProvider.overrideWithValue(FakeBillingGateway()),
        onboardingStoreProvider.overrideWithValue(onboardingStore),
        cameraRepositoryProvider.overrideWithValue(cameraRepository),
        voiceRepositoryProvider.overrideWithValue(_StubVoiceRepository()),
        volumeRepositoryProvider.overrideWithValue(_StubVolumeRepository()),
        voiceWakeEventsProvider.overrideWithValue(
          const Stream<WakeCommand>.empty(),
        ),
        voiceStateEventsProvider.overrideWithValue(
          const Stream<VoiceListeningState>.empty(),
        ),
        vaultServiceProvider.overrideWith(
          (ref) async => VaultService(documentsDir: vaultRoot),
        ),
        videoListProvider.overrideWith((ref) async => seededVideos),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        routerConfig: buildAppRouter(),
      ),
    );
  }

  group('appRouter', () {
    testWidgets('inicia no splash (/splash)', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.byKey(const Key('splash_logo')), findsOneWidget);
    });

    testWidgets('splash → onboarding 1 quando onboarding incompleto', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      expect(find.text('Grave sem tocar'), findsOneWidget);
    });

    testWidgets('splash → camera direto quando onboarding completo', (
      tester,
    ) async {
      onboardingStore.completed = true;
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RecButton), findsOneWidget);
    });

    testWidgets('onboarding 1 → Avançar → onboarding 2', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Nunca perca o momento'), findsOneWidget);
    });

    testWidgets('onboarding 2 → Avançar → permissions (P04)', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Permissões essenciais'), findsOneWidget);
    });

    testWidgets('onboarding 1 → Pular → permissions (P04)', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      expect(find.text('Permissões essenciais'), findsOneWidget);
    });

    Future<void> goToCamera(WidgetTester tester) async {
      when(gateway.requestCamera).thenAnswer((_) async => true);
      when(gateway.requestMicrophone).thenAnswer((_) async => true);
      when(gateway.requestNotification).thenAnswer((_) async => true);
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      // Camera tem animações infinitas (buffer pill pulse) → pumpAndSettle
      // nunca converge; pump bounded deixa a transição de rota completar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('permissions → Continuar (granted) → camera (P05)', (
      tester,
    ) async {
      await goToCamera(tester);
      expect(find.byType(RecButton), findsOneWidget);
    });

    testWidgets('camera → settings (P06) abre a tela real', (tester) async {
      await goToCamera(tester);
      await tester.tap(find.byKey(const Key('camera_settings_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Qualidade de Gravação'), findsOneWidget);
    });

    testWidgets('camera → gallery (P07) abre a tela real', (tester) async {
      await goToCamera(tester);
      await tester.tap(find.byKey(const Key('camera_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Galeria'), findsOneWidget);
    });

    testWidgets('gallery → tap thumbnail → preview (P08) abre a tela real', (
      tester,
    ) async {
      seededVideos = [
        VideoEntity(
          id: 'demo',
          name: 'Vídeo demo',
          duration: const Duration(seconds: 12),
          recordedAt: DateTime(2026, 6, 4, 9, 41),
          isReplay: false,
          thumbnailHue: 200,
        ),
      ];
      await goToCamera(tester);
      await tester.tap(find.byKey(const Key('camera_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byType(VideoThumbnail).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('INFO'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
    });

    testWidgets('camera → popup M01 → paywall → checkout → confirma → camera', (
      tester,
    ) async {
      await goToCamera(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Assinatura necessária'), findsOneWidget);

      await tester.tap(find.text('Assinar agora'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Escolha seu plano'), findsOneWidget);

      await tester.tap(find.text('Assinar agora'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Finalizar assinatura'), findsOneWidget);

      await tester.tap(find.text('Confirmar assinatura'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(RecButton), findsOneWidget);
      expect(subscriptionStore.stored.isSubscribed, isTrue);
    });
  });
}
