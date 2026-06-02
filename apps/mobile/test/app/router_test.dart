import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/app/router.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';

void main() {
  Widget app() {
    return ProviderScope(
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

    testWidgets('onboarding 2 → Avançar → permissions placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('permissions_placeholder')), findsOneWidget);
    });

    testWidgets('onboarding 1 → Pular → permissions placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('permissions_placeholder')), findsOneWidget);
    });
  });
}
