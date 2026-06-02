import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';

class MicHaloIcon extends StatelessWidget {
  const MicHaloIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112 + 56,
      height: 112 + 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _halo(112 + 56, 0.05),
          _halo(112 + 24, 0.05),
          _halo(112, 0.10),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  RaroAccents.orange.withValues(alpha: 0.20),
                  RaroAccents.orange.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
          const Icon(Icons.mic_none_rounded, size: 38, color: Colors.white),
        ],
      ),
    );
  }

  Widget _halo(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: opacity)),
      ),
    );
  }
}
