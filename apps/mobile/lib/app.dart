import 'package:flutter/material.dart';
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
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Center(
        child: Text(
          'RARO',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 48,
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
