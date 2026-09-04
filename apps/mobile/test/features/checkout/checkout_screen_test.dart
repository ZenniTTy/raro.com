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
import 'package:raro_mobile/features/checkout/presentation/checkout_screen.dart';
import 'package:raro_mobile/features/gallery/data/system_gallery_exporter_provider.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_billing_gateway.dart';
import '../../helpers/fake_system_gallery_exporter.dart';

class _FakeSubscriptionStore implements SubscriptionStore {
  SubscriptionState stored = const SubscriptionState.initial();
  int saveCount = 0;

  @override
  Future<SubscriptionState> load() async => stored;

  @override
  Future<void> save(SubscriptionState state) async {
    stored = state;
    saveCount++;
  }
}

class _MockCameraRepository extends Mock implements CameraRepository {}

PendingClip _pendingClip() {
  return PendingClip(
    path: '/tmp/raro_checkout_pending.mp4',
    metadata: RecordingMetadata(
      id: 'pend-fail',
      name: 'Vídeo 09:41',
      duration: const Duration(seconds: 5),
      recordedAt: DateTime(2026, 9, 4, 9, 41),
      isReplay: false,
      thumbnailHue: 20,
    ),
  );
}

void main() {
  late _FakeSubscriptionStore store;
  late FakeBillingGateway billing;
  bool confirmed = false;
  String? savedId;

  Widget app(PlanType plan) {
    store = _FakeSubscriptionStore();
    billing = FakeBillingGateway();
    confirmed = false;
    return ProviderScope(
      overrides: [
        subscriptionStoreProvider.overrideWithValue(store),
        billingGatewayProvider.overrideWithValue(billing),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: CheckoutScreen(
          plan: plan,
          onBack: () {},
          onConfirmed: () => confirmed = true,
        ),
      ),
    );
  }

  Future<void> pumpReady(WidgetTester tester, PlanType plan) async {
    await tester.pumpWidget(app(plan));
    await tester.pump();
  }

  testWidgets('mostra título e resumo com período de teste de 30 dias', (
    tester,
  ) async {
    await pumpReady(tester, PlanType.monthly);
    expect(find.text('Finalizar assinatura'), findsOneWidget);
    expect(find.textContaining('30 dias'), findsWidgets);
  });

  testWidgets('plano mensal mostra R\$ 9,90 no resumo', (tester) async {
    await pumpReady(tester, PlanType.monthly);
    expect(find.textContaining('R\$ 9,90'), findsWidgets);
  });

  testWidgets('não mostra seletor Apple Pay / Google Play', (tester) async {
    await pumpReady(tester, PlanType.monthly);
    expect(find.text('Apple Pay'), findsNothing);
    expect(find.text('Google Play'), findsNothing);
  });

  testWidgets('confirmar dispara compra e onConfirmed', (tester) async {
    await pumpReady(tester, PlanType.monthly);
    await tester.tap(find.text('Confirmar assinatura'));
    await tester.pump();
    await tester.pump();
    expect(confirmed, isTrue);
    expect(store.saveCount, 1);
    expect(store.stored.isSubscribed, isTrue);
    expect(billing.premium, isTrue);
  });

  testWidgets('compra ok e persist falho não navega como salvo', (
    tester,
  ) async {
    store = _FakeSubscriptionStore();
    confirmed = false;
    savedId = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStoreProvider.overrideWithValue(store),
          billingGatewayProvider.overrideWithValue(
            EntitledThenUnavailableBillingGateway(),
          ),
          pendingRecordingProvider.overrideWithValue(_pendingClip()),
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
          home: CheckoutScreen(
            plan: PlanType.monthly,
            onBack: () {},
            onConfirmed: () => confirmed = true,
            onPendingSaved: (id) => savedId = id,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Confirmar assinatura'));
    await tester.pump();
    await tester.pump();
    expect(confirmed, isFalse);
    expect(savedId, isNull);
    expect(
      find.text('Não foi possível guardar o vídeo. Tente de novo.'),
      findsOneWidget,
    );
    expect(store.stored.isSubscribed, isTrue);
  });
}
