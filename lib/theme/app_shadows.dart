import 'package:flutter/material.dart';

class SafeShadow {
  static Shadow build({
    required Color color,
    required double blur,
  }) {
    return Shadow(
      color: color,
      blurRadius: blur < 0 ? 0 : blur,
    );
  }
}

class SafeBoxShadow {
  static BoxShadow build({
    Color color = const Color(0xFF000000),
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
    double spreadRadius = 0.0,
  }) {
    return BoxShadow(
      color: color,
      offset: offset,
      blurRadius: blurRadius < 0 ? 0 : blurRadius,
      spreadRadius: spreadRadius,
    );
  }
}

class AppShadows {
  static final purpleGlow = [
    SafeShadow.build(
      color: const Color(0xFFEA80FC),
      blur: 10,
    ),
  ];

  static final whiteSoft = [
    SafeShadow.build(
      color: const Color(0x88FFFFFF),
      blur: 10,
    ),
  ];

  static final blackSoft = [
    SafeShadow.build(
      color: const Color(0x73000000),
      blur: 4,
    ),
  ];
}
