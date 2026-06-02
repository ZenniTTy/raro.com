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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        final t = _breathe.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  RaroAccents.orange,
                  RaroAccents.yellow,
                  t,
                )!.withValues(alpha: 0.20 + 0.15 * t),
                blurRadius: 18 + 14 * t,
                spreadRadius: 2 * t,
              ),
              BoxShadow(
                color: Color.lerp(
                  RaroAccents.blue,
                  RaroAccents.purple,
                  t,
                )!.withValues(alpha: 0.15 + 0.10 * t),
                blurRadius: 48 + 22 * t,
                spreadRadius: 4 * t,
              ),
            ],
          ),
          child: child,
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
