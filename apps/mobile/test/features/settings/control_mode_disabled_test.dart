import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/settings/presentation/widgets/control_mode_card.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildRaroDarkTheme(),
    home: Scaffold(body: child),
  );

  testWidgets('card desabilitado mostra "em breve" e não dispara onTap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        ControlModeCard(
          badge: 'OFF',
          title: 'Volume',
          subtitle: '+ ou −',
          active: false,
          onTap: () => tapped = true,
          enabled: false,
        ),
      ),
    );
    expect(find.textContaining('em breve'), findsOneWidget);
    await tester.tap(find.byType(ControlModeCard));
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('card habilitado dispara onTap normalmente', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        ControlModeCard(
          badge: 'ON',
          title: 'Voz ativa',
          subtitle: 'Diga "Raro"',
          active: true,
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.byType(ControlModeCard));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
