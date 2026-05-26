import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';

class RaroApp extends StatelessWidget {
  const RaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raro Camera',
      debugShowCheckedModeBanner: false,
      theme: buildRaroDarkTheme(),
      home: const _BootstrapPlaceholder(),
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
