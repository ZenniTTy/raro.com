import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/checkout/presentation/checkout_screen.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';

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
  bool confirmed = false;

  Widget app(PlanType plan) {
    store = _FakeSubscriptionStore();
    confirmed = false;
    return ProviderScope(
      overrides: [subscriptionStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
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

  testWidgets('mostra os 2 métodos de pagamento Apple Pay e Google Play', (
    tester,
  ) async {
    await pumpReady(tester, PlanType.monthly);
    expect(find.text('Apple Pay'), findsOneWidget);
    expect(find.text('Google Play'), findsOneWidget);
  });

  testWidgets('hint inicial pede para selecionar método', (tester) async {
    await pumpReady(tester, PlanType.monthly);
    expect(find.text('SELECIONE UM MÉTODO ACIMA'), findsOneWidget);
  });

  testWidgets('confirmar sem método selecionado não dispara onConfirmed', (
    tester,
  ) async {
    await pumpReady(tester, PlanType.monthly);
    await tester.tap(find.text('Confirmar assinatura'), warnIfMissed: false);
    await tester.pump();
    expect(confirmed, isFalse);
    expect(store.saveCount, 0);
  });

  testWidgets('selecionar Apple Pay + confirmar marca assinado e dispara cb', (
    tester,
  ) async {
    await pumpReady(tester, PlanType.monthly);
    await tester.tap(find.text('Apple Pay'));
    await tester.pump();
    await tester.tap(find.text('Confirmar assinatura'));
    await tester.pump();
    await tester.pump();
    expect(confirmed, isTrue);
    expect(store.saveCount, 1);
    expect(store.stored.isSubscribed, isTrue);
    expect(store.stored.trialStartedAt, isNotNull);
  });
}
