import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'RARO',
          style: TextStyle(
            fontFamily: RaroFonts.mono,
            fontSize: 11,
            letterSpacing: 1.98,
            color: colors.inkFaint,
          ),
        ),
        TextButton(
          onPressed: onSkip,
          child: Text(
            AppLocalizations.of(context).onboardingSkip,
            style: TextStyle(
              fontFamily: RaroFonts.body,
              fontSize: 14,
              color: colors.inkDim,
            ),
          ),
        ),
      ],
    );
  }
}
