import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';

void main() {
  group('RaroFonts', () {
    test('font families match the pubspec-registered families', () {
      expect(RaroFonts.display, 'Space Grotesk');
      expect(RaroFonts.body, 'Inter');
      expect(RaroFonts.mono, 'JetBrains Mono');
    });
  });

  group('buildRaroDarkTheme', () {
    test('uses Inter as the default UI font family', () {
      final theme = buildRaroDarkTheme();
      expect(theme.textTheme.bodyMedium?.fontFamily, RaroFonts.body);
    });

    test('display text styles use Space Grotesk', () {
      final theme = buildRaroDarkTheme();
      expect(theme.textTheme.displayLarge?.fontFamily, RaroFonts.display);
      expect(theme.textTheme.headlineLarge?.fontFamily, RaroFonts.display);
    });

    test('keeps brightness dark and bgDeep scaffold background', () {
      final theme = buildRaroDarkTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    });
  });
}
