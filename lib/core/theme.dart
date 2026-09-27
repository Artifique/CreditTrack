import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Legacy AppColors aliased to AppTokens for backwards compatibility
class AppColors {
  static const Color primary = AppTokens.primary500;
  static const Color primaryDark = AppTokens.primary600;
  static const Color secondary = AppTokens.secondary500;
  static const Color background = AppTokens.lightBg;
  static const Color surface = AppTokens.lightSurface;
  static const Color textPrimary = AppTokens.lightTextPrimary;
  static const Color textSecondary = AppTokens.lightTextSecondary;

  // Semantics
  static const Color success = AppTokens.success;
  static const Color warning = AppTokens.warning;
  static const Color error = AppTokens.error;
  static const Color info = AppTokens.info;

  // Gradients
  static const LinearGradient primaryGradient = AppTokens.primaryGradient;
  static const LinearGradient secondaryGradient = AppTokens.secondaryGradient;
  static const LinearGradient cardGradientUV = AppTokens.cardGradientUV;
  static const LinearGradient cardGradientCredit = AppTokens.cardGradientCredit;
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = AppTokens.textTheme(AppTokens.lightTextPrimary, AppTokens.lightTextSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppTokens.lightBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppTokens.primary500,
        onPrimary: Colors.white,
        primaryContainer: AppTokens.primary50,
        onPrimaryContainer: AppTokens.primary800,
        secondary: AppTokens.secondary500,
        onSecondary: Colors.white,
        secondaryContainer: AppTokens.secondary50,
        onSecondaryContainer: AppTokens.secondary700,
        error: AppTokens.error,
        onError: Colors.white,
        errorContainer: AppTokens.errorBg,
        onErrorContainer: AppTokens.errorText,
        surface: AppTokens.lightSurface,
        onSurface: AppTokens.lightTextPrimary,
        surfaceContainerHighest: AppTokens.lightBgSubtle,
        onSurfaceVariant: AppTokens.lightTextSecondary,
        outline: AppTokens.lightBorder,
        outlineVariant: AppTokens.lightBorderHover,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTokens.lightBg,
        foregroundColor: AppTokens.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppTokens.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          side: const BorderSide(color: AppTokens.lightBorder, width: 1),
        ),
        color: AppTokens.lightSurface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppTokens.lightTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.primary500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppTokens.lightSurface,
        selectedItemColor: AppTokens.primary500,
        unselectedItemColor: AppTokens.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = AppTokens.textTheme(AppTokens.darkTextPrimary, AppTokens.darkTextSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTokens.darkBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppTokens.primary400,
        onPrimary: Color(0xFF0F172A),
        primaryContainer: AppTokens.primary900,
        onPrimaryContainer: AppTokens.primary100,
        secondary: AppTokens.secondary400,
        onSecondary: Color(0xFF064E3B),
        secondaryContainer: Color(0xFF064E3B),
        onSecondaryContainer: AppTokens.secondary100,
        error: AppTokens.error,
        onError: Colors.white,
        errorContainer: AppTokens.darkErrorBg,
        onErrorContainer: AppTokens.darkErrorText,
        surface: AppTokens.darkSurface,
        onSurface: AppTokens.darkTextPrimary,
        surfaceContainerHighest: AppTokens.darkBgSubtle,
        onSurfaceVariant: AppTokens.darkTextSecondary,
        outline: AppTokens.darkBorder,
        outlineVariant: AppTokens.darkBorderHover,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTokens.darkBg,
        foregroundColor: AppTokens.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppTokens.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          side: const BorderSide(color: AppTokens.darkBorder, width: 1),
        ),
        color: AppTokens.darkSurface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.darkBgSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppTokens.darkTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.darkBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.darkBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.primary400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppTokens.darkSurface,
        selectedItemColor: AppTokens.primary400,
        unselectedItemColor: AppTokens.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
