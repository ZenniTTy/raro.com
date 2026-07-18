import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class BufferVisualization extends StatelessWidget {
  const BufferVisualization({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final labelStyle = TextStyle(
      fontFamily: RaroFonts.mono,
      fontSize: 10,
      letterSpacing: 1.5,
      color: colors.inkFaint,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).bufferVisualizationLabel,
                style: labelStyle,
              ),
              Text(
                AppLocalizations.of(context).bufferVisualizationNow,
                style: labelStyle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.bgElev,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderBright),
            ),
            child: CustomPaint(
              painter: _WaveformPainter(),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).bufferVisualizationCaption,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 9,
              color: colors.inkDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  static const int barCount = 40;
  static const double switchFraction = 0.65;

  @override
  void paint(Canvas canvas, Size size) {
    final markerX = size.width * switchFraction;

    final pastRect = Rect.fromLTWH(0, 0, markerX, size.height);
    canvas.drawRect(
      pastRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            RaroAccents.orange.withValues(alpha: 0.15),
            RaroAccents.green.withValues(alpha: 0.2),
          ],
        ).createShader(pastRect),
    );

    final nowRect = Rect.fromLTWH(
      markerX,
      0,
      size.width - markerX,
      size.height,
    );
    canvas.saveLayer(
      nowRect,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawRect(
      nowRect,
      Paint()..shader = RaroGradients.rainbow.createShader(nowRect),
    );
    canvas.restore();

    final slot = size.width / barCount;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < barCount; i++) {
      final h = 10 + (math.sin(i * 0.7).abs() * 22);
      final x = slot * i + slot / 2;
      final past = i / barCount < switchFraction;
      paint
        ..color = Colors.white.withValues(alpha: past ? 0.15 : 0.7)
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }

    canvas.drawLine(
      Offset(markerX, 0),
      Offset(markerX, size.height),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => false;
}
