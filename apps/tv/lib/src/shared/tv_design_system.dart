import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class TvDesignSystem {
  TvDesignSystem._();

  // ─── Color Palette ─── (Matching Mobile AppColors)
  static const Color primary = AppColors.primaryValue; // Electric Blue 2026
  static const Color secondary = Color(0xFF60A5FA);
  static const Color accent = AppColors.primaryValue;
  static const Color background = AppColors.backgroundColor; // OLED Black
  static const Color surface = Color(0xFF121212); // Dark Grey Surface
  static const Color textBody = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);

  // Focus colors
  static const Color focusColor = Colors.white;
  static const Color focusBorderColor = Colors.white;

  // Tab active
  static const Color tabActive = AppColors.primaryValue;

  // ─── Typography (TV 10-foot UI) ───
  static const TextStyle displayLarge = TextStyle(
    color: Colors.white,
    fontSize: 60,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -2,
  );

  static const TextStyle displayMedium = TextStyle(
    color: Colors.white,
    fontSize: 44,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: -1,
  );

  static const TextStyle headlineLarge = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static const TextStyle titleLarge = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleMedium = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: Colors.white70,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelLarge = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  );

  static const TextStyle labelSmall = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ─── Border Radius (Refined for a cleaner look) ───
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 100.0;

  // ─── Overscan Safe Area ───
  static const double overscanMargin = 48.0;
  static const EdgeInsets overscanPadding = EdgeInsets.all(48.0);

  // ─── Card Dimensions ───
  static const double cardWidthPortrait = 220.0;
  static const double cardWidthLandscape = 340.0;
  static const double shelfPaddingLeft = 80.0;

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Spacing ───
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  static const double space3xl = 64.0;

  // ─── Animations ───
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationSlow = Duration(milliseconds: 600);
  static const Curve curveFluid = Curves.easeOutQuart;

  // ─── Shadows ───
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 25,
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> focusGlow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.15),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
