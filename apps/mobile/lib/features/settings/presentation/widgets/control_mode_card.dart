import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';

class ControlModeCard extends StatelessWidget {
  const ControlModeCard({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    this.enabled = true,
  });

  final String badge;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? RaroAccents.selectedSurface : colors.bgCard,
            border: Border.all(
              color: active ? Colors.white : colors.borderBright,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    badge,
                    style: TextStyle(
                      fontFamily: RaroFonts.mono,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      color: active ? Colors.white : colors.inkFaint,
                    ),
                  ),
                  if (active) const _RainbowCheck(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                enabled ? subtitle : 'em breve',
                style: TextStyle(
                  fontFamily: RaroFonts.mono,
                  fontSize: 11,
                  color: colors.inkDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RainbowCheck extends StatelessWidget {
  const _RainbowCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RaroGradients.redRadial,
      ),
      child: const Icon(Icons.check, size: 11, color: Colors.white),
    );
  }
}
