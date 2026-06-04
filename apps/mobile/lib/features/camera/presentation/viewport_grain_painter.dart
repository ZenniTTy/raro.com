import 'dart:math';

import 'package:flutter/material.dart';

class ViewportGrainPainter extends CustomPainter {
  const ViewportGrainPainter({this.seed = 42});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    final dotCount = (size.width * size.height / 600).round();
    for (var i = 0; i < dotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ViewportGrainPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
