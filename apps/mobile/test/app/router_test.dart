import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/app/router.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/permissions/application/permission_status_provider.dart';
import 'package:raro_mobile/features/gallery/presentation/widgets/video_thumbnail.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/permissions/data/permission_gateway.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/data/settings_store.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';

class _MockPermissionGateway extends Mock implements PermissionGateway {}

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

void main() {
  late _MockPermissionGateway gateway;
  late _FakeSubscriptionStore subscriptionStore;

  setUp(() {
    gateway = _MockPermissionGateway();
    when(gateway.cameraStatus).thenAnswer((_) async => false);
    when(gateway.microphoneStatus).thenAnswer((_) async => false);
    subscriptionStore = _FakeSubscriptionStore();
  });

  Widget app() {
    return ProviderScope(
      overrides: [
        permissionGatewayProvider.overrideWithValue(gateway),
        settingsStoreProvider.overrideWithValue(_FakeSettingsStore()),
        subscriptionStoreProvider.overrideWithValue(subscriptionStore),
      ],
      child: MaterialApp.router(
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

    testWidgets('splash auto-navega para onboarding 1 após 1.8s', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      expect(find.text('Grave sem tocar'), findsOneWidget);
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
      expect(find.text('DIGA “RARO” PARA GRAVAR'), findsOneWidget);
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

      await tester.tap(find.text('Apple Pay'));
      await tester.pump();
      await tester.tap(find.text('Confirmar assinatura'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('DIGA “RARO” PARA GRAVAR'), findsOneWidget);
      expect(subscriptionStore.stored.isSubscribed, isTrue);
    });
  });
}
