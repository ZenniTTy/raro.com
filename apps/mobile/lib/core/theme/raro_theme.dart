import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'raro_theme.tailor.dart';

@TailorMixin()
class RaroColors extends ThemeExtension<RaroColors>
    with _$RaroColorsTailorMixin {
  const RaroColors({
    required this.bgDeep,
    required this.bgElev,
    required this.bgCard,
    required this.ink,
    required this.inkDim,
    required this.inkFaint,
    required this.border,
    required this.borderBright,
    required this.raroRed,
  });

  @override
  final Color bgDeep;
  @override
  final Color bgElev;
  @override
  final Color bgCard;
  @override
  final Color ink;
  @override
  final Color inkDim;
  @override
  final Color inkFaint;
  @override
  final Color border;
  @override
  final Color borderBright;
  @override
  final Color raroRed;

  static const RaroColors dark = RaroColors(
    bgDeep: Color(0xFF000000),
    bgElev: Color(0xFF0A0A0A),
    bgCard: Color(0xFF141414),
    ink: Color(0xFFFFFFFF),
    inkDim: Color(0xFFA3A3A3),
    inkFaint: Color(0xFF525252),
    border: Color(0xFF1F1F1F),
    borderBright: Color(0xFF2E2E2E),
    raroRed: Color(0xFFFF2D55),
  );
}

@TailorMixin()
class RaroRadii extends ThemeExtension<RaroRadii> with _$RaroRadiiTailorMixin {
  const RaroRadii({
    required this.card,
    required this.button,
    required this.pill,
    required this.chip,
    required this.sheetTop,
    required this.phone,
  });

  @override
  final double card;
  @override
  final double button;
  @override
  final double pill;
  @override
  final double chip;
  @override
  final double sheetTop;
  @override
  final double phone;

  static const RaroRadii dark = RaroRadii(
    card: 16,
    button: 16,
    pill: 999,
    chip: 10,
    sheetTop: 24,
    phone: 50,
  );
}

@TailorMixin()
class RaroSpacing extends ThemeExtension<RaroSpacing>
    with _$RaroSpacingTailorMixin {
  const RaroSpacing({
    required this.x05,
    required this.x1,
    required this.x2,
    required this.x3,
    required this.x4,
    required this.x5,
    required this.x6,
    required this.x7,
    required this.x10,
    required this.x12,
  });

  @override
  final double x05;
  @override
  final double x1;
  @override
  final double x2;
  @override
  final double x3;
  @override
  final double x4;
  @override
  final double x5;
  @override
  final double x6;
  @override
  final double x7;
  @override
  final double x10;
  @override
  final double x12;

  static const RaroSpacing dark = RaroSpacing(
    x05: 2,
    x1: 4,
    x2: 8,
    x3: 12,
    x4: 16,
    x5: 20,
    x6: 24,
    x7: 28,
    x10: 40,
    x12: 48,
  );
}

@TailorMixin()
class RaroDurations extends ThemeExtension<RaroDurations>
    with _$RaroDurationsTailorMixin {
  const RaroDurations({
    required this.logoBreathe,
    required this.recPulse,
    required this.lensSwitchBlur,
    required this.focusRing,
    required this.gradShift,
    required this.planHueSpin,
    required this.touchActive,
  });

  @override
  final Duration logoBreathe;
  @override
  final Duration recPulse;
  @override
  final Duration lensSwitchBlur;
  @override
  final Duration focusRing;
  @override
  final Duration gradShift;
  @override
  final Duration planHueSpin;
  @override
  final Duration touchActive;

  static const RaroDurations dark = RaroDurations(
    logoBreathe: Duration(milliseconds: 3400),
    recPulse: Duration(milliseconds: 1200),
    lensSwitchBlur: Duration(milliseconds: 220),
    focusRing: Duration(milliseconds: 1200),
    gradShift: Duration(milliseconds: 5000),
    planHueSpin: Duration(milliseconds: 6000),
    touchActive: Duration(milliseconds: 120),
  );
}
