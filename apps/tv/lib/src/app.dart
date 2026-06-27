import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'shared/tv_design_system.dart';

class TvApp extends StatelessWidget {
  const TvApp({super.key});

  static final _tvTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: TvDesignSystem.background,
    colorScheme: ColorScheme.dark(
      primary: TvDesignSystem.primary,
      secondary: TvDesignSystem.secondary,
      surface: TvDesignSystem.surface,
      error: TvDesignSystem.accent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      selectedColor: TvDesignSystem.primary,
      labelStyle: TvDesignSystem.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TvDesignSystem.radiusMd),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TvDesignSystem.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TvDesignSystem.radiusLg),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      titleTextStyle: TvDesignSystem.headlineMedium,
      contentTextStyle: TvDesignSystem.bodyMedium,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TvDesignSystem.primary,
    ),
    textTheme: const TextTheme(
      displayLarge: TvDesignSystem.displayLarge,
      displayMedium: TvDesignSystem.displayMedium,
      headlineLarge: TvDesignSystem.headlineLarge,
      headlineMedium: TvDesignSystem.headlineMedium,
      titleLarge: TvDesignSystem.titleLarge,
      titleMedium: TvDesignSystem.titleMedium,
      bodyLarge: TvDesignSystem.bodyLarge,
      bodyMedium: TvDesignSystem.bodyMedium,
      labelLarge: TvDesignSystem.labelLarge,
      labelSmall: TvDesignSystem.labelSmall,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TMovie TV',
      debugShowCheckedModeBanner: false,
      theme: _tvTheme,
      routerConfig: tvRouter,
    );
  }
}
