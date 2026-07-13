import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/app/router.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/application/camera_analytics_listener.dart';
import 'package:raro_mobile/features/camera/presentation/camera_test_harness_screen.dart';

const bool _forceHarness = bool.fromEnvironment('RARO_HARNESS');

class RaroApp extends ConsumerWidget {
  const RaroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cameraAnalyticsListenerProvider);
    final theme = buildRaroDarkTheme();
    if (_forceHarness) {
      return MaterialApp(
        title: 'Raro Camera',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const CameraTestHarnessScreen(),
      );
    }
    return MaterialApp.router(
      title: 'Raro Camera',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: buildAppRouter(),
    );
  }
}
