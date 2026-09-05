import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/camera_repository_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:raro_mobile/features/camera/data/vault_service_provider.dart';
import 'package:raro_mobile/features/camera/domain/pending_clip.dart';
import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/paywall_intent.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/paywall/presentation/paywall_screen.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_billing_gateway.dart';
import '../../helpers/fake_system_gallery_exporter.dart';

class _MemorySubscriptionStore implements SubscriptionStore {
  SubscriptionState stored = const SubscriptionState.initial();

  @override
  Future<SubscriptionState> load() async => stored;

  @override
  Future<void> save(SubscriptionState state) async {
    stored = state;
  }
}

void main() {
  PlanType? checkoutPlan;
  var closed = false;

  Widget app({FakeBillingGateway? gateway}) {
    checkoutPlan = null;
    closed = false;
    return ProviderScope(
      overrides: [
        billingGatewayProvider.overrideWithValue(
          gateway ?? FakeBillingGateway(),
        ),
        subscriptionStoreProvider.overrideWithValue(_MemorySubscriptionStore()),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: PaywallScreen(
          onClose: () => closed = true,
          onCheckout: (plan) => checkoutPlan = plan,
          onTerms: () {},
          onPrivacy: () {},
        ),
      ),
    );
  }

  testWidgets('mostra título e os 2 planos com preços do contrato', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('Escolha seu plano'), findsOneWidget);
    expect(find.textContaining('R\$ 9,90'), findsWidgets);
    expect(find.textContaining('R\$ 89,90'), findsWidgets);
    expect(find.text('MELHOR OFERTA'), findsOneWidget);
  });

  testWidgets('subtítulo menciona 30 dias grátis (invariante, não 15)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.textContaining('30 dias'), findsWidgets);
    expect(find.textContaining('15 dias'), findsNothing);
  });

  testWidgets('features aparecem dentro de cada card (1 por plano)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('Gravação em 4K 60fps'), findsNWidgets(2));
    expect(find.text('Sem anúncios'), findsNWidgets(2));
  });

  testWidgets('mensal selecionado por padrão; CTA leva o plano ao checkout', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Assinar agora'));
    await tester.pump();
    expect(checkoutPlan, PlanType.monthly);
  });

  testWidgets('selecionar o card anual muda o plano levado ao checkout', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('plan_card_yearly')));
    await tester.pump();
    await tester.tap(find.text('Assinar agora'));
    await tester.pump();
    expect(checkoutPlan, PlanType.yearly);
  });

  testWidgets('copy 2.8 cita Play, 30 dias e renovação automática', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.textContaining('renovação automática'), findsOneWidget);
    expect(find.textContaining('30 dias grátis'), findsWidgets);
    expect(find.textContaining('Google Play'), findsOneWidget);
    expect(find.textContaining('App Store'), findsOneWidget);
    expect(
      find.textContaining('Desinstalar o app não cancela a assinatura'),
      findsOneWidget,
    );
  });

  testWidgets('links legais disparam onTerms e onPrivacy', (tester) async {
    var terms = 0;
    var privacy = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billingGatewayProvider.overrideWithValue(FakeBillingGateway()),
          subscriptionStoreProvider.overrideWithValue(
            _MemorySubscriptionStore(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PaywallScreen(
            onClose: () {},
            onCheckout: (_) {},
            onTerms: () => terms++,
            onPrivacy: () => privacy++,
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('paywall_terms_link')),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('paywall_terms_link')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('paywall_privacy_link')));
    await tester.pump();
    expect(terms, 1);
    expect(privacy, 1);
    expect(find.text('Em breve'), findsNothing);
  });

  testWidgets('mostra "Restaurar compras" e "Voltar"', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Restaurar compras'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
  });

  testWidgets('restore vazio mostra snackbar, não "Em breve"', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Restaurar compras'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Nenhuma compra para restaurar neste aparelho.'),
      findsOneWidget,
    );
    expect(find.text('Em breve'), findsNothing);
    expect(closed, isFalse);
  });

  testWidgets('restore com premium fecha o paywall', (tester) async {
    await tester.pumpWidget(app(gateway: FakeBillingGateway(premium: true)));
    await tester.tap(find.text('Restaurar compras'));
    await tester.pump();
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('intent save usa copy de guardar e menciona 30 dias', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billingGatewayProvider.overrideWithValue(FakeBillingGateway()),
          subscriptionStoreProvider.overrideWithValue(
            _MemorySubscriptionStore(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PaywallScreen(
            intent: PaywallIntent.save,
            onClose: () {},
            onCheckout: (_) {},
            onTerms: () {},
            onPrivacy: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('guardar este vídeo'), findsOneWidget);
    expect(find.textContaining('30 dias'), findsWidgets);
  });

  testWidgets('restore save com persist falho não trata como desbloqueio', (
    tester,
  ) async {
    var unlocked = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billingGatewayProvider.overrideWithValue(
            EntitledThenUnavailableBillingGateway(),
          ),
          subscriptionStoreProvider.overrideWithValue(
            _MemorySubscriptionStore(),
          ),
          pendingRecordingProvider.overrideWithValue(
            PendingClip(
              path: '/tmp/raro_missing_restore.mp4',
              metadata: RecordingMetadata(
                id: 'pend-restore',
                name: 'Vídeo 09:41',
                duration: const Duration(seconds: 5),
                recordedAt: DateTime(2026, 9, 4, 9, 41),
                isReplay: false,
                thumbnailHue: 20,
              ),
            ),
          ),
          vaultServiceProvider.overrideWith(
            (ref) => VaultService(documentsDir: Directory.systemTemp),
          ),
          systemGalleryExporterProvider.overrideWithValue(
            FakeSystemGalleryExporter(),
          ),
          cameraRepositoryProvider.overrideWithValue(_MockCameraRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PaywallScreen(
            intent: PaywallIntent.save,
            onClose: () {},
            onCheckout: (_) {},
            onTerms: () {},
            onPrivacy: () {},
            onUnlocked: () => unlocked = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Restaurar compras'));
    await tester.pump();
    await tester.pump();
    expect(unlocked, isFalse);
    expect(
      find.text('Não foi possível guardar o vídeo. Tente de novo.'),
      findsOneWidget,
    );
  });
}

class _MockCameraRepository extends Mock implements CameraRepository {}
