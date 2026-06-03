import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/presentation/paywall_screen.dart';

void main() {
  PlanType? checkoutPlan;

  Widget app() {
    checkoutPlan = null;
    return ProviderScope(
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: PaywallScreen(
          onClose: () {},
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
}
