import 'package:flutter/material.dart';

class RuleOfThirdsPainter extends CustomPainter {
  const RuleOfThirdsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    final w3 = size.width / 3;
    final h3 = size.height / 3;
    canvas.drawLine(Offset(w3, 0), Offset(w3, size.height), paint);
    canvas.drawLine(Offset(w3 * 2, 0), Offset(w3 * 2, size.height), paint);
    canvas.drawLine(Offset(0, h3), Offset(size.width, h3), paint);
    canvas.drawLine(Offset(0, h3 * 2), Offset(size.width, h3 * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
