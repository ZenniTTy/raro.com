import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class ReplayArmRing extends StatefulWidget {
  const ReplayArmRing({
    super.key,
    required this.armed,
    required this.windowSeconds,
    required this.recording,
    required this.child,
  });

  final bool armed;
  final int windowSeconds;
  final bool recording;
  final Widget child;

  @override
  State<ReplayArmRing> createState() => _ReplayArmRingState();
}

class _ReplayArmRingState extends State<ReplayArmRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.windowSeconds),
    );
    if (_showRing) _fill.forward();
  }

  bool get _showRing => widget.armed && !widget.recording;

  @override
  void didUpdateWidget(ReplayArmRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.windowSeconds != oldWidget.windowSeconds) {
      _fill.duration = Duration(seconds: widget.windowSeconds);
    }
    if (_showRing && !oldWidget.armed) {
      _fill
        ..value = 0
        ..forward();
    } else if (!_showRing && _showRingFor(oldWidget)) {
      _fill.stop();
    }
  }

  bool _showRingFor(ReplayArmRing w) => w.armed && !w.recording;

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showRing) return widget.child;
    return AnimatedBuilder(
      animation: _fill,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: ReplayArmRingPainter(progress: _fill.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ReplayArmRingPainter extends CustomPainter {
  const ReplayArmRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) + 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final sweep = 2 * 3.1415926535 * progress.clamp(0.0, 1.0);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = RaroAccents.teal;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(ReplayArmRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
