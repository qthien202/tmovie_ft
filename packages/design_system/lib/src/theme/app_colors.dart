import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryValue = Color(0xff3B82F6); // Electric Blue 2026
  static const Color backgroundColor = Color(0xff050505); // OLED Black
  static const Color surfaceColor = Color(0xff121212); // Dark Grey Surface
  static const Color container = Color(0xff1F1D2B);

  static MaterialColor primary =
      MaterialColor(primaryValue.toARGB32(), <int, Color>{
        50: Color(primaryValue.toARGB32() - 0xcc000000),
        100: Color(primaryValue.toARGB32() - 0xaa000000),
        200: Color(primaryValue.toARGB32() - 0x99000000),
        300: Color(primaryValue.toARGB32() - 0x55000000),
        400: Color(primaryValue.toARGB32() - 0x11000000),
        500: primaryValue,
        600: Color(primaryValue.toARGB32() + 0x11000000),
        700: Color(primaryValue.toARGB32() + 0x55000000),
        800: Color(primaryValue.toARGB32() + 0x99000000),
        900: Color(primaryValue.toARGB32() + 0xff000000),
      });
}
