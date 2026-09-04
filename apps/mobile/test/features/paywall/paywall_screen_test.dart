import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/data/subscription_store.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/domain/subscription_state.dart';
import 'package:raro_mobile/features/paywall/presentation/paywall_screen.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_billing_gateway.dart';

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
}
