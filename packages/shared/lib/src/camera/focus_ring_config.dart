class FocusRingConfig {
  const FocusRingConfig._();

  static const int colorArgb = 0xFFFFFFFF;
  static const double strokeWidth = 1.5;
  static const int durationMs = 1200;
  static const double scaleFrom = 1.4;
  static const double scaleTo = 1.0;
  static const double radiusPx = 32.0;
  static const List<double> opacityKeyframes = [0.0, 1.0, 0.0];
  static const List<double> opacityKeyTimes = [0.0, 0.2, 1.0];
}
