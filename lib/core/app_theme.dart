import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ),

    scaffoldBackgroundColor: AppColors.background,

    primaryColor: AppColors.primary,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(AppColors.primary),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(AppColors.primary),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.primary),
      trackColor: WidgetStateProperty.all(
        AppColors.primary.withOpacity(.4),
      ),
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withOpacity(.3),
      selectionHandleColor: AppColors.primary,
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
      ),
    ),
  );
}