import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class RecButton extends StatefulWidget {
  const RecButton({super.key, required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  State<RecButton> createState() => _RecButtonState();
}

class _RecButtonState extends State<RecButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.recording) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RecButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.recording) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? Colors.black : RaroAccents.red,
          boxShadow: [
            BoxShadow(
              color: RaroAccents.red.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: -10,
            ),
          ],
          border: recording
              ? const Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 3),
                )
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
        ),
        alignment: Alignment.center,
        child: recording
            ? FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.55).animate(_pulse),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: RaroAccents.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: RaroAccents.red,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
