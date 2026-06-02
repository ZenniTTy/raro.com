import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';

class BufferPill extends StatefulWidget {
  const BufferPill({super.key, required this.duration, required this.onTap});

  final BufferDuration duration;
  final VoidCallback onTap;

  @override
  State<BufferPill> createState() => _BufferPillState();
}

class _BufferPillState extends State<BufferPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: ShapeDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: StadiumBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.4).animate(_pulse),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: RaroAccents.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: RaroAccents.red, blurRadius: 8)],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Raro Replay ${widget.duration.seconds}s',
              style: const TextStyle(
                fontFamily: RaroFonts.mono,
                fontSize: 10,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
