import 'package:flutter/widgets.dart';

/// Soft black shadows. No coloured glow (kept the UI from looking "AI").
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
