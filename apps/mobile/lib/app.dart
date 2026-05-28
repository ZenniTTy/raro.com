import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/camera/presentation/camera_test_harness_screen.dart';

const bool _forceHarness = bool.fromEnvironment(
  'RARO_HARNESS',
  defaultValue: true,
);

class RaroApp extends StatelessWidget {
  const RaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    const showHarness = kDebugMode || _forceHarness;
    return MaterialApp(
      title: 'Raro Camera',
      debugShowCheckedModeBanner: false,
      theme: buildRaroDarkTheme(),
      home: showHarness
          ? const CameraTestHarnessScreen()
          : const _BootstrapPlaceholder(),
    );
  }
}

class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Center(
        child: Text(
          'RARO',
          style: TextStyle(
            color: colors.ink,
            fontSize: 48,
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
