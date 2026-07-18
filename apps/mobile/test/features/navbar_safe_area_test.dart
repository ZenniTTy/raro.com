import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:raro_mobile/features/permissions/presentation/permissions_screen.dart';
import 'package:raro_mobile/features/settings/presentation/settings_screen.dart';
import 'package:raro_mobile/features/splash/presentation/splash_screen.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class _FakeOnboardingStore implements OnboardingStore {
  @override
  Future<bool> isCompleted() async => false;

  @override
  Future<void> markCompleted() async {}
}

void _expectSafeAreaUnderScaffold() {
  expect(
    find.descendant(of: find.byType(Scaffold), matching: find.byType(SafeArea)),
    findsWidgets,
  );
}

void main() {
  testWidgets('GalleryScreen envolve o conteudo em SafeArea', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [videoListProvider.overrideWith((ref) async => const [])],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: GalleryScreen(onBack: () {}, onOpenVideo: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    _expectSafeAreaUnderScaffold();
  });

  testWidgets('PermissionsScreen envolve o conteudo em SafeArea', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: PermissionsScreen(onGranted: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    _expectSafeAreaUnderScaffold();
  });

  testWidgets('SettingsScreen envolve o conteudo em SafeArea', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: SettingsScreen(onBack: () {}, onSeePlans: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    _expectSafeAreaUnderScaffold();
  });

  testWidgets('SplashScreen envolve o conteudo em SafeArea', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStoreProvider.overrideWithValue(_FakeOnboardingStore()),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildRaroDarkTheme(),
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    _expectSafeAreaUnderScaffold();
    // Splash agenda auto-nav por timer; drenar para não vazar pending timer.
    await tester.pump(const Duration(milliseconds: 1800));
  });
}
