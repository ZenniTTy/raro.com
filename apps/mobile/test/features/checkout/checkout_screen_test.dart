import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/checkout/presentation/checkout_screen.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_billing_gateway.dart';

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

void main() {
  late _FakeSubscriptionStore store;
  late FakeBillingGateway billing;
  bool confirmed = false;

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
}
