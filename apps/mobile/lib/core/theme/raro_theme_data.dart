import 'package:flutter/material.dart';

import 'raro_fonts.dart';
import 'raro_theme.dart';

ThemeData buildRaroDarkTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: RaroColors.dark.bgDeep,
    fontFamily: RaroFonts.body,
    extensions: const <ThemeExtension<dynamic>>[
      RaroColors.dark,
      RaroRadii.dark,
      RaroSpacing.dark,
      RaroDurations.dark,
    ],
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: RaroFonts.display,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontFamily: RaroFonts.display,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: RaroFonts.display,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: RaroFonts.display,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: RaroFonts.display,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: RaroFonts.display,
      ),
    ),
  );
}
