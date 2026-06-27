import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        primaryColor: AppColors.backgroundColor,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryValue,
          surface: AppColors.surfaceColor,
        ),
      );
}
