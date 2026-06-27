import 'package:flutter/material.dart';

/// TMovie color tokens.
/// Brand = Transformative Teal (WGSN Colour of the Year 2026).
class AppColors {
  AppColors._();

  // ── Brand ──
  static const Color primaryValue = Color(0xFF0FA3A3); // Transformative Teal
  static const Color primaryDim = Color(0xFF0B7A7A); // pressed / gradient end
  static const Color secondary = Color(0xFF4FD1C5); // mint highlight
  static const Color onPrimary = Color(0xFF04201F); // text/icon on teal

  // ── Surfaces ──
  static const Color backgroundColor = Color(0xFF0A0C0C);
  static const Color surfaceColor = Color(0xFF12181A);
  static const Color surfaceElevated = Color(0xFF182225);
  static const Color container = surfaceElevated; // legacy alias
  static const Color border = Color(0xFF243033);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9BA8AB);
  static const Color textTertiary = Color(0xFF5E6B6E);

  // ── Accents / states ──
  static const Color rating = Color(0xFFF5C518); // IMDb gold
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // ── Material swatch (kept for legacy `AppColors.primary`) ──
  static final MaterialColor primary =
      MaterialColor(primaryValue.toARGB32(), const <int, Color>{
    50: Color(0xFFE0F2F2),
    100: Color(0xFFB3DEDE),
    200: Color(0xFF80C9C9),
    300: Color(0xFF4DB3B3),
    400: Color(0xFF26A3A3),
    500: primaryValue,
    600: Color(0xFF0D9494),
    700: primaryDim,
    800: Color(0xFF096060),
    900: Color(0xFF053D3D),
  });
}
