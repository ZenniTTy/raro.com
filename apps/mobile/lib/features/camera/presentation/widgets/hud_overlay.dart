import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class HudInfoBar extends StatelessWidget {
  const HudInfoBar({
    super.key,
    required this.resolutionLabel,
    required this.fpsLabel,
    required this.lensLabel,
    required this.onTap,
  });

  final String resolutionLabel;
  final String fpsLabel;
  final String lensLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        '$resolutionLabel · $fpsLabel · $lensLabel',
        style: const TextStyle(
          fontFamily: RaroFonts.mono,
          fontSize: 11,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class RecIndicator extends StatefulWidget {
  const RecIndicator({super.key, required this.elapsed});

  final Duration elapsed;

  @override
  State<RecIndicator> createState() => _RecIndicatorState();
}

class _RecIndicatorState extends State<RecIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.55).animate(_pulse),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: RaroAccents.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _format(widget.elapsed),
            style: const TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class CameraCenterHint extends StatelessWidget {
  const CameraCenterHint({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_outlined,
            size: 42,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'DIGA “RARO” PARA GRAVAR',
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 10,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
