import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/splash/presentation/widgets/breathing_logo.dart';
import 'package:raro_mobile/features/splash/presentation/widgets/dot_loader.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  static const Duration holdDuration = Duration(milliseconds: 1800);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.holdDuration, () {
      if (!mounted) return;
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BreathingLogo(),
                SizedBox(height: 32),
                DotLoader(key: Key('splash_loader')),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Text(
              'CAPTURE · UNSCRIPTED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: RaroFonts.mono,
                fontSize: 10,
                letterSpacing: 2,
                color: colors.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
