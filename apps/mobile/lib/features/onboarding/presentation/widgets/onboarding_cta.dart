import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';

class OnboardingCta extends StatelessWidget {
  const OnboardingCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final radii = Theme.of(context).extension<RaroRadii>()!;

    final text = Text(
      label,
      style: TextStyle(
        fontFamily: RaroFonts.body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary ? Colors.black : colors.ink,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radii.button),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: primary ? RaroGradients.rainbow : null,
              color: primary ? null : colors.bgElev,
              borderRadius: BorderRadius.circular(radii.button),
              border: primary ? null : Border.all(color: colors.borderBright),
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: text,
            ),
          ),
        ),
      ),
    );
  }
}
