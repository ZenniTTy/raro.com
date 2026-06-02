import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_1.dart';

void main() {
  Widget harness({VoidCallback? onNext, VoidCallback? onSkip}) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: OnboardingPage1(onNext: onNext ?? () {}, onSkip: onSkip ?? () {}),
      ),
    );
  }

  group('OnboardingPage1', () {
    testWidgets('mostra título "Grave sem tocar"', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('Grave sem tocar'), findsOneWidget);
    });

    testWidgets('mostra o subtexto "— O RARO escuta."', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('— O RARO escuta.'), findsOneWidget);
    });

    testWidgets('mostra header RARO e botão Pular', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('RARO'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
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

    testWidgets('Avançar avança o provider para replay', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildRaroDarkTheme(),
            home: OnboardingPage1(onNext: () {}, onSkip: () {}),
          ),
        ),
      );
      await tester.tap(find.text('Avançar'));
      await tester.pump();
      expect(container.read(onboardingProgressProvider), OnboardingStep.replay);
    });
  });
}
