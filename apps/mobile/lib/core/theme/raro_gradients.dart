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
    stops: [0, 0.16, 0.33, 0.50, 0.66, 0.83, 1.0],
  );

  static const RadialGradient redRadial = RadialGradient(
    colors: [Color(0xFFFF5470), Color(0xFFFF2D55), Color(0xFFC8002A)],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient modalBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x80FF2D55),
      Color(0x4DFFCC00),
      Color(0x6600C7BE),
      Color(0x80AF52DE),
    ],
    stops: [0, 0.3, 0.6, 1],
  );

  static const LinearGradient planCardBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [RaroAccents.yellow, RaroAccents.orange, RaroAccents.red],
  );

  static const RadialGradient paywallGlowWarm = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 0.9,
    colors: [Color(0x14FF6B35), Color(0x00000000)],
  );

  static const RadialGradient paywallGlowCool = RadialGradient(
    radius: 0.8,
    colors: [Color(0x0F007AFF), Color(0x00000000)],
  );
}
