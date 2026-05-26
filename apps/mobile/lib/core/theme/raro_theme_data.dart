import 'package:flutter/material.dart';

import 'raro_theme.dart';

ThemeData buildRaroDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: RaroColors.dark.bgDeep,
    extensions: const <ThemeExtension<dynamic>>[
      RaroColors.dark,
      RaroRadii.dark,
      RaroSpacing.dark,
      RaroDurations.dark,
    ],
  );
}
