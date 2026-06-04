import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/paywall/presentation/widgets/subscription_popup.dart';

void main() {
  Widget host({
    required VoidCallback onSubscribe,
    required VoidCallback onLater,
  }) {
    return MaterialApp(
      theme: buildRaroDarkTheme(),
      home: Scaffold(
        body: SubscriptionPopup(onSubscribe: onSubscribe, onLater: onLater),
      ),
    );
  }

  testWidgets('mostra título "Assinatura necessária" e label ASSINATURA', (
    tester,
  ) async {
    await tester.pumpWidget(host(onSubscribe: () {}, onLater: () {}));
    expect(find.text('ASSINATURA'), findsOneWidget);
    expect(find.textContaining('Assinatura necessária'), findsOneWidget);
  });

  testWidgets('menciona 30 dias grátis (invariante, não os 15 do protótipo)', (
    tester,
  ) async {
    await tester.pumpWidget(host(onSubscribe: () {}, onLater: () {}));
    expect(find.textContaining('30 dias'), findsOneWidget);
    expect(find.textContaining('15 dias'), findsNothing);
  });

  testWidgets('CTA "Assinar agora" dispara onSubscribe', (tester) async {
    var subscribed = false;
    await tester.pumpWidget(
      host(onSubscribe: () => subscribed = true, onLater: () {}),
    );
    await tester.tap(find.text('Assinar agora'));
    await tester.pump();
    expect(subscribed, isTrue);
  });

  testWidgets('CTA "Talvez depois" dispara onLater', (tester) async {
    var later = false;
    await tester.pumpWidget(
      host(onSubscribe: () {}, onLater: () => later = true),
    );
    await tester.tap(find.text('Talvez depois'));
    await tester.pump();
    expect(later, isTrue);
  });
}
