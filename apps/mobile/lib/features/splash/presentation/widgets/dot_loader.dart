import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class DotLoader extends StatefulWidget {
  const DotLoader({super.key});

  static const List<Color> _dotColors = [
    RaroAccents.orange,
    RaroAccents.green,
    RaroAccents.blue,
  ];

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scaleFor(double t, double delayFraction) {
    final shifted = (t - delayFraction) % 1.0;
    if (shifted < 0 || shifted > 0.8) {
      return 1;
    }
    final peak = (0.4 - (shifted - 0.4).abs()) / 0.4;
    return 1 + 0.3 * peak.clamp(0.0, 1.0);
  }

  double _glowFor(double t, double delayFraction) {
    final shifted = (t - delayFraction) % 1.0;
    if (shifted < 0 || shifted > 0.8) {
      return 0;
    }
    final peak = (0.4 - (shifted - 0.4).abs()) / 0.4;
    return peak.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    const delays = [0.0, 0.143, 0.286];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _Dot(
                color: DotLoader._dotColors[i],
                scale: _scaleFor(t, delays[i]),
                glow: _glowFor(t, delays[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.scale, required this.glow});

  final Color color;
  final double scale;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final active = glow > 0.01;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : RaroAccents.dotIdle,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6 * glow),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
