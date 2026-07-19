import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:raro_mobile/features/splash/presentation/splash_screen.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class _FakeOnboardingStore implements OnboardingStore {
  _FakeOnboardingStore({this.completed = false});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

void main() {
  Widget harness({
    ValueChanged<bool>? onComplete,
    bool onboardingCompleted = false,
  }) {
    return ProviderScope(
      overrides: [
        onboardingStoreProvider.overrideWithValue(
          _FakeOnboardingStore(completed: onboardingCompleted),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildRaroDarkTheme(),
        home: SplashScreen(onComplete: onComplete),
      ),
    );
  }

  group('SplashScreen', () {
    testWidgets('mostra logo + dot loader + tagline', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.byKey(const Key('splash_logo')), findsOneWidget);
      expect(find.byKey(const Key('splash_loader')), findsOneWidget);
      expect(find.text('CAPTURE · UNSCRIPTED'), findsOneWidget);

      // limpa o timer pendente de auto-nav
      await tester.pump(const Duration(milliseconds: 1800));
    });

    testWidgets('tagline usa JetBrains Mono', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      final tagline = tester.widget<Text>(find.text('CAPTURE · UNSCRIPTED'));
      expect(tagline.style?.fontFamily, RaroFonts.mono);

      await tester.pump(const Duration(milliseconds: 1800));
    });

    testWidgets('chama onComplete após 1.8s', (tester) async {
      var called = false;
      await tester.pumpWidget(harness(onComplete: (_) => called = true));
      await tester.pump();

      expect(called, isFalse);
      await tester.pump(const Duration(milliseconds: 1799));
      expect(called, isFalse);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('onComplete recebe false quando onboarding incompleto', (
      tester,
    ) async {
      bool? received;
      await tester.pumpWidget(harness(onComplete: (value) => received = value));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1801));
      await tester.pump();

      expect(received, isFalse);
    });

    testWidgets('onComplete recebe true quando onboarding completo', (
      tester,
    ) async {
      bool? received;
      await tester.pumpWidget(
        harness(
          onComplete: (value) => received = value,
          onboardingCompleted: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1801));
      await tester.pump();

      expect(received, isTrue);
    });

    testWidgets('não chama onComplete se desmontado antes de 1.8s', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(harness(onComplete: (_) => called = true));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStoreProvider.overrideWithValue(_FakeOnboardingStore()),
          ],
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();

      expect(called, isFalse);
    });
  });
}
