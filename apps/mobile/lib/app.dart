import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/l10n/app_locale.dart';
import 'package:raro_mobile/app/router.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/camera_analytics_listener.dart';
import 'package:raro_mobile/features/camera/presentation/camera_test_harness_screen.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

const bool _forceHarness = bool.fromEnvironment('RARO_HARNESS');

class RaroApp extends ConsumerWidget {
  const RaroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cameraAnalyticsListenerProvider);
    final language = ref.watch(settingsControllerProvider).value?.language;
    final locale = localeForLanguage(language);
    final theme = buildRaroDarkTheme();
    if (_forceHarness) {
      return MaterialApp(
        title: 'Raro Camera',
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CameraTestHarnessScreen(),
      );
    }
    return MaterialApp.router(
      title: 'Raro Camera',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: buildAppRouter(),
    );
  }
}
