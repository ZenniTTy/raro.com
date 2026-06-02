import 'package:flutter/material.dart';

abstract final class RaroAccents {
  static const Color red = Color(0xFFFF2D55);
  static const Color orange = Color(0xFFFF6B35);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color green = Color(0xFF34C759);
  static const Color teal = Color(0xFF00C7BE);
  static const Color blue = Color(0xFF007AFF);
  static const Color purple = Color(0xFFAF52DE);

  static const Color dotIdle = Color(0xFF333333);
  static const Color selectedSurface = Color(0xFF1A1A1A);
}

abstract final class RaroGradients {
  static const LinearGradient rainbow = LinearGradient(
    colors: [
      RaroAccents.red,
      RaroAccents.orange,
      RaroAccents.yellow,
      RaroAccents.green,
      RaroAccents.teal,
      RaroAccents.blue,
      RaroAccents.purple,
    ],
  );

  static const RadialGradient redRadial = RadialGradient(
    colors: [Color(0xFFFF5470), Color(0xFFFF2D55), Color(0xFFC8002A)],
    stops: [0.0, 0.6, 1.0],
  );
}
