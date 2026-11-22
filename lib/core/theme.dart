import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_color_palette.dart';
import 'tokens.dart';

/// Legacy AppColors aliased to AppTokens for backwards compatibility
class AppColors {
  static Color get primary => AppTokens.primary500;
  static Color get primaryDark => AppTokens.primary600;
  static Color get secondary => AppTokens.secondary500;
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
  static LinearGradient get primaryGradient => AppTokens.primaryGradient;
  static LinearGradient get secondaryGradient => AppTokens.secondaryGradient;
  static LinearGradient get cardGradientUV => AppTokens.cardGradientUV;
  static LinearGradient get cardGradientCredit => AppTokens.cardGradientCredit;
  static LinearGradient get cardGradientCash => AppTokens.cardGradientCash;
}

class AppTheme {
  static ThemeData get lightTheme => buildLightTheme();
  static ThemeData get darkTheme => buildDarkTheme();

  static ThemeData buildLightTheme([AppColorPalette? palette]) {
    final p = palette ?? AppTokens.currentPalette;
    final textTheme = AppTokens.textTheme(
        AppTokens.lightTextPrimary, AppTokens.lightTextSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppTokens.lightBg,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: p.primary500,
        onPrimary: Colors.white,
        primaryContainer: p.primary50,
        onPrimaryContainer: p.primary800,
        secondary: p.secondary500,
        onSecondary: Colors.white,
        secondaryContainer: p.secondary50,
        onSecondaryContainer: p.secondary700,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppTokens.lightTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide:
              const BorderSide(color: AppTokens.lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide:
              const BorderSide(color: AppTokens.lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: p.primary500, width: 2),
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
          backgroundColor: p.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize:
              const Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppTokens.lightSurface,
        selectedItemColor: p.primary500,
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

  static ThemeData buildDarkTheme([AppColorPalette? palette]) {
    final p = palette ?? AppTokens.currentPalette;
    final textTheme = AppTokens.textTheme(
        AppTokens.darkTextPrimary, AppTokens.darkTextSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTokens.darkBg,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: p.primary400,
        onPrimary: const Color(0xFF0F172A),
        primaryContainer: p.primary900,
        onPrimaryContainer: p.primary100,
        secondary: p.secondary400,
        onSecondary: const Color(0xFF064E3B),
        secondaryContainer: const Color(0xFF064E3B),
        onSecondaryContainer: p.secondary100,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: p.primary400, width: 2),
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
          backgroundColor: p.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize:
              const Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppTokens.darkSurface,
        selectedItemColor: p.primary400,
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
