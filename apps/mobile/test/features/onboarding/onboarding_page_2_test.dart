import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_2.dart';
import 'package:raro_mobile/features/onboarding/presentation/widgets/onboarding_cta.dart';

void main() {
  Widget harness({VoidCallback? onNext, VoidCallback? onSkip}) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: OnboardingPage2(onNext: onNext ?? () {}, onSkip: onSkip ?? () {}),
      ),
    );
  }

  group('OnboardingPage2', () {
    testWidgets('mostra título "Nunca perca o momento"', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('Nunca perca o momento'), findsOneWidget);
    });

    testWidgets('mostra o label do buffer "BUFFER · 15s"', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('BUFFER · 15s'), findsOneWidget);
      expect(find.text('AGORA'), findsOneWidget);
    });

    testWidgets('botão Avançar chama onNext', (tester) async {
      var nexted = false;
      await tester.pumpWidget(harness(onNext: () => nexted = true));
      await tester.tap(find.text('Avançar'));
      await tester.pump();
      expect(nexted, isTrue);
    });

    testWidgets('botão Pular chama onSkip', (tester) async {
      var skipped = false;
      await tester.pumpWidget(harness(onSkip: () => skipped = true));
      await tester.tap(find.text('Pular'));
      await tester.pump();
      expect(skipped, isTrue);
    });

    testWidgets('CTA Avançar é primário (gradient)', (tester) async {
      await tester.pumpWidget(harness());
      final cta = tester.widget<OnboardingCta>(
        find.widgetWithText(OnboardingCta, 'Avançar'),
      );
      expect(cta.primary, isTrue);
    });
  });
}
