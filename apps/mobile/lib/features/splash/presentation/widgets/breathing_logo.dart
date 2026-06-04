import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class BreathingLogo extends StatefulWidget {
  const BreathingLogo({super.key, this.size = 220});

  final double size;

  @override
  State<BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  late final Animation<double> _breathe = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _glowLayer({
    required Color color,
    required double blurSigma,
    required double opacity,
  }) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Opacity(
        opacity: opacity,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
          child: Image.asset(
            'assets/logo/raro_logo.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        final t = _breathe.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            _glowLayer(
              color: Color.lerp(RaroAccents.orange, RaroAccents.yellow, t)!,
              blurSigma: 9 + 7 * t,
              opacity: 0.20 + 0.15 * t,
            ),
            _glowLayer(
              color: Color.lerp(RaroAccents.blue, RaroAccents.purple, t)!,
              blurSigma: 24 + 11 * t,
              opacity: 0.15 + 0.10 * t,
            ),
            child!,
          ],
        );
      },
      child: Image.asset(
        'assets/logo/raro_logo.png',
        key: const Key('splash_logo'),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
