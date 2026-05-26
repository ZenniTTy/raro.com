// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raro_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$RaroColorsTailorMixin on ThemeExtension<RaroColors> {
  Color get bgDeep;
  Color get bgElev;
  Color get bgCard;
  Color get ink;
  Color get inkDim;
  Color get inkFaint;
  Color get border;
  Color get borderBright;
  Color get raroRed;

  @override
  RaroColors copyWith({
    Color? bgDeep,
    Color? bgElev,
    Color? bgCard,
    Color? ink,
    Color? inkDim,
    Color? inkFaint,
    Color? border,
    Color? borderBright,
    Color? raroRed,
  }) {
    return RaroColors(
      bgDeep: bgDeep ?? this.bgDeep,
      bgElev: bgElev ?? this.bgElev,
      bgCard: bgCard ?? this.bgCard,
      ink: ink ?? this.ink,
      inkDim: inkDim ?? this.inkDim,
      inkFaint: inkFaint ?? this.inkFaint,
      border: border ?? this.border,
      borderBright: borderBright ?? this.borderBright,
      raroRed: raroRed ?? this.raroRed,
    );
  }

  @override
  RaroColors lerp(covariant ThemeExtension<RaroColors>? other, double t) {
    if (other is! RaroColors) return this as RaroColors;
    return RaroColors(
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      bgElev: Color.lerp(bgElev, other.bgElev, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkDim: Color.lerp(inkDim, other.inkDim, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderBright: Color.lerp(borderBright, other.borderBright, t)!,
      raroRed: Color.lerp(raroRed, other.raroRed, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RaroColors &&
            const DeepCollectionEquality().equals(bgDeep, other.bgDeep) &&
            const DeepCollectionEquality().equals(bgElev, other.bgElev) &&
            const DeepCollectionEquality().equals(bgCard, other.bgCard) &&
            const DeepCollectionEquality().equals(ink, other.ink) &&
            const DeepCollectionEquality().equals(inkDim, other.inkDim) &&
            const DeepCollectionEquality().equals(inkFaint, other.inkFaint) &&
            const DeepCollectionEquality().equals(border, other.border) &&
            const DeepCollectionEquality().equals(
              borderBright,
              other.borderBright,
            ) &&
            const DeepCollectionEquality().equals(raroRed, other.raroRed));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(bgDeep),
      const DeepCollectionEquality().hash(bgElev),
      const DeepCollectionEquality().hash(bgCard),
      const DeepCollectionEquality().hash(ink),
      const DeepCollectionEquality().hash(inkDim),
      const DeepCollectionEquality().hash(inkFaint),
      const DeepCollectionEquality().hash(border),
      const DeepCollectionEquality().hash(borderBright),
      const DeepCollectionEquality().hash(raroRed),
    );
  }
}

extension RaroColorsBuildContextProps on BuildContext {
  RaroColors get raroColors => Theme.of(this).extension<RaroColors>()!;
  Color get bgDeep => raroColors.bgDeep;
  Color get bgElev => raroColors.bgElev;
  Color get bgCard => raroColors.bgCard;
  Color get ink => raroColors.ink;
  Color get inkDim => raroColors.inkDim;
  Color get inkFaint => raroColors.inkFaint;
  Color get border => raroColors.border;
  Color get borderBright => raroColors.borderBright;
  Color get raroRed => raroColors.raroRed;
}

mixin _$RaroRadiiTailorMixin on ThemeExtension<RaroRadii> {
  double get card;
  double get button;
  double get pill;
  double get chip;
  double get sheetTop;
  double get phone;

  @override
  RaroRadii copyWith({
    double? card,
    double? button,
    double? pill,
    double? chip,
    double? sheetTop,
    double? phone,
  }) {
    return RaroRadii(
      card: card ?? this.card,
      button: button ?? this.button,
      pill: pill ?? this.pill,
      chip: chip ?? this.chip,
      sheetTop: sheetTop ?? this.sheetTop,
      phone: phone ?? this.phone,
    );
  }

  @override
  RaroRadii lerp(covariant ThemeExtension<RaroRadii>? other, double t) {
    if (other is! RaroRadii) return this as RaroRadii;
    return RaroRadii(
      card: t < 0.5 ? card : other.card,
      button: t < 0.5 ? button : other.button,
      pill: t < 0.5 ? pill : other.pill,
      chip: t < 0.5 ? chip : other.chip,
      sheetTop: t < 0.5 ? sheetTop : other.sheetTop,
      phone: t < 0.5 ? phone : other.phone,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RaroRadii &&
            const DeepCollectionEquality().equals(card, other.card) &&
            const DeepCollectionEquality().equals(button, other.button) &&
            const DeepCollectionEquality().equals(pill, other.pill) &&
            const DeepCollectionEquality().equals(chip, other.chip) &&
            const DeepCollectionEquality().equals(sheetTop, other.sheetTop) &&
            const DeepCollectionEquality().equals(phone, other.phone));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(card),
      const DeepCollectionEquality().hash(button),
      const DeepCollectionEquality().hash(pill),
      const DeepCollectionEquality().hash(chip),
      const DeepCollectionEquality().hash(sheetTop),
      const DeepCollectionEquality().hash(phone),
    );
  }
}

extension RaroRadiiBuildContextProps on BuildContext {
  RaroRadii get raroRadii => Theme.of(this).extension<RaroRadii>()!;
  double get card => raroRadii.card;
  double get button => raroRadii.button;
  double get pill => raroRadii.pill;
  double get chip => raroRadii.chip;
  double get sheetTop => raroRadii.sheetTop;
  double get phone => raroRadii.phone;
}

mixin _$RaroSpacingTailorMixin on ThemeExtension<RaroSpacing> {
  double get x05;
  double get x1;
  double get x2;
  double get x3;
  double get x4;
  double get x5;
  double get x6;
  double get x7;
  double get x10;
  double get x12;

  @override
  RaroSpacing copyWith({
    double? x05,
    double? x1,
    double? x2,
    double? x3,
    double? x4,
    double? x5,
    double? x6,
    double? x7,
    double? x10,
    double? x12,
  }) {
    return RaroSpacing(
      x05: x05 ?? this.x05,
      x1: x1 ?? this.x1,
      x2: x2 ?? this.x2,
      x3: x3 ?? this.x3,
      x4: x4 ?? this.x4,
      x5: x5 ?? this.x5,
      x6: x6 ?? this.x6,
      x7: x7 ?? this.x7,
      x10: x10 ?? this.x10,
      x12: x12 ?? this.x12,
    );
  }

  @override
  RaroSpacing lerp(covariant ThemeExtension<RaroSpacing>? other, double t) {
    if (other is! RaroSpacing) return this as RaroSpacing;
    return RaroSpacing(
      x05: t < 0.5 ? x05 : other.x05,
      x1: t < 0.5 ? x1 : other.x1,
      x2: t < 0.5 ? x2 : other.x2,
      x3: t < 0.5 ? x3 : other.x3,
      x4: t < 0.5 ? x4 : other.x4,
      x5: t < 0.5 ? x5 : other.x5,
      x6: t < 0.5 ? x6 : other.x6,
      x7: t < 0.5 ? x7 : other.x7,
      x10: t < 0.5 ? x10 : other.x10,
      x12: t < 0.5 ? x12 : other.x12,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RaroSpacing &&
            const DeepCollectionEquality().equals(x05, other.x05) &&
            const DeepCollectionEquality().equals(x1, other.x1) &&
            const DeepCollectionEquality().equals(x2, other.x2) &&
            const DeepCollectionEquality().equals(x3, other.x3) &&
            const DeepCollectionEquality().equals(x4, other.x4) &&
            const DeepCollectionEquality().equals(x5, other.x5) &&
            const DeepCollectionEquality().equals(x6, other.x6) &&
            const DeepCollectionEquality().equals(x7, other.x7) &&
            const DeepCollectionEquality().equals(x10, other.x10) &&
            const DeepCollectionEquality().equals(x12, other.x12));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(x05),
      const DeepCollectionEquality().hash(x1),
      const DeepCollectionEquality().hash(x2),
      const DeepCollectionEquality().hash(x3),
      const DeepCollectionEquality().hash(x4),
      const DeepCollectionEquality().hash(x5),
      const DeepCollectionEquality().hash(x6),
      const DeepCollectionEquality().hash(x7),
      const DeepCollectionEquality().hash(x10),
      const DeepCollectionEquality().hash(x12),
    );
  }
}

extension RaroSpacingBuildContextProps on BuildContext {
  RaroSpacing get raroSpacing => Theme.of(this).extension<RaroSpacing>()!;
  double get x05 => raroSpacing.x05;
  double get x1 => raroSpacing.x1;
  double get x2 => raroSpacing.x2;
  double get x3 => raroSpacing.x3;
  double get x4 => raroSpacing.x4;
  double get x5 => raroSpacing.x5;
  double get x6 => raroSpacing.x6;
  double get x7 => raroSpacing.x7;
  double get x10 => raroSpacing.x10;
  double get x12 => raroSpacing.x12;
}

mixin _$RaroDurationsTailorMixin on ThemeExtension<RaroDurations> {
  Duration get logoBreathe;
  Duration get recPulse;
  Duration get lensSwitchBlur;
  Duration get focusRing;
  Duration get gradShift;
  Duration get planHueSpin;
  Duration get touchActive;

  @override
  RaroDurations copyWith({
    Duration? logoBreathe,
    Duration? recPulse,
    Duration? lensSwitchBlur,
    Duration? focusRing,
    Duration? gradShift,
    Duration? planHueSpin,
    Duration? touchActive,
  }) {
    return RaroDurations(
      logoBreathe: logoBreathe ?? this.logoBreathe,
      recPulse: recPulse ?? this.recPulse,
      lensSwitchBlur: lensSwitchBlur ?? this.lensSwitchBlur,
      focusRing: focusRing ?? this.focusRing,
      gradShift: gradShift ?? this.gradShift,
      planHueSpin: planHueSpin ?? this.planHueSpin,
      touchActive: touchActive ?? this.touchActive,
    );
  }

  @override
  RaroDurations lerp(covariant ThemeExtension<RaroDurations>? other, double t) {
    if (other is! RaroDurations) return this as RaroDurations;
    return RaroDurations(
      logoBreathe: t < 0.5 ? logoBreathe : other.logoBreathe,
      recPulse: t < 0.5 ? recPulse : other.recPulse,
      lensSwitchBlur: t < 0.5 ? lensSwitchBlur : other.lensSwitchBlur,
      focusRing: t < 0.5 ? focusRing : other.focusRing,
      gradShift: t < 0.5 ? gradShift : other.gradShift,
      planHueSpin: t < 0.5 ? planHueSpin : other.planHueSpin,
      touchActive: t < 0.5 ? touchActive : other.touchActive,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RaroDurations &&
            const DeepCollectionEquality().equals(
              logoBreathe,
              other.logoBreathe,
            ) &&
            const DeepCollectionEquality().equals(recPulse, other.recPulse) &&
            const DeepCollectionEquality().equals(
              lensSwitchBlur,
              other.lensSwitchBlur,
            ) &&
            const DeepCollectionEquality().equals(focusRing, other.focusRing) &&
            const DeepCollectionEquality().equals(gradShift, other.gradShift) &&
            const DeepCollectionEquality().equals(
              planHueSpin,
              other.planHueSpin,
            ) &&
            const DeepCollectionEquality().equals(
              touchActive,
              other.touchActive,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(logoBreathe),
      const DeepCollectionEquality().hash(recPulse),
      const DeepCollectionEquality().hash(lensSwitchBlur),
      const DeepCollectionEquality().hash(focusRing),
      const DeepCollectionEquality().hash(gradShift),
      const DeepCollectionEquality().hash(planHueSpin),
      const DeepCollectionEquality().hash(touchActive),
    );
  }
}

extension RaroDurationsBuildContextProps on BuildContext {
  RaroDurations get raroDurations => Theme.of(this).extension<RaroDurations>()!;
  Duration get logoBreathe => raroDurations.logoBreathe;
  Duration get recPulse => raroDurations.recPulse;
  Duration get lensSwitchBlur => raroDurations.lensSwitchBlur;
  Duration get focusRing => raroDurations.focusRing;
  Duration get gradShift => raroDurations.gradShift;
  Duration get planHueSpin => raroDurations.planHueSpin;
  Duration get touchActive => raroDurations.touchActive;
}
