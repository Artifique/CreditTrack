import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_palette.dart';

/// Design System Tokens for CreditTrak
/// Standardized Design Tokens matching src/styles/tokens.css
class AppTokens {
  AppTokens._();

  // ---------------------------------------------------------------------------
  // 1. PALETTE DYNAMIQUE (5 Thèmes au choix)
  // ---------------------------------------------------------------------------
  static AppColorPalette _currentPalette = AppColorPalette.orange;

  static void setPalette(AppColorPalette palette) {
    _currentPalette = palette;
  }

  static AppColorPalette get currentPalette => _currentPalette;

  // Nuances primaires dynamiques
  static Color get primary50 => _currentPalette.primary50;
  static Color get primary100 => _currentPalette.primary100;
  static Color get primary200 => _currentPalette.primary200;
  static Color get primary300 => _currentPalette.primary300;
  static Color get primary400 => _currentPalette.primary400;
  static Color get primary500 => _currentPalette.primary500;
  static Color get primary600 => _currentPalette.primary600;
  static Color get primary700 => _currentPalette.primary700;
  static Color get primary800 => _currentPalette.primary800;
  static Color get primary900 => _currentPalette.primary900;

  // Nuances secondaires dynamiques
  static Color get secondary50 => _currentPalette.secondary50;
  static Color get secondary100 => _currentPalette.secondary100;
  static Color get secondary200 => _currentPalette.secondary200;
  static Color get secondary300 => _currentPalette.secondary300;
  static Color get secondary400 => _currentPalette.secondary400;
  static Color get secondary500 => _currentPalette.secondary500;
  static Color get secondary600 => _currentPalette.secondary600;
  static Color get secondary700 => _currentPalette.secondary700;

  // Marque Telecom / UV : Orange Solaire Pur (Orange Money / Opérations)
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange500 = Color(0xFFFF6600);
  static const Color orange600 = Color(0xFFEA580C);

  // Semantics - Haute saturation & contraste calibré
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF065F46);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFF92400E);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorText = Color(0xFF991B1B);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoText = Color(0xFF0369A1);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Quick aliases
  static Color get primary => primary500;
  static Color get secondary => secondary500;

  // Neutres Mode Clair - Haute définition & contraste certifié WCAG AAA
  static const Color lightBg =
      Color(0xFFF8FAFC); // Blanc albâtre subtil, reposant pour les yeux
  static const Color lightBgSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color lightSurface =
      Color(0xFFFFFFFF); // Blanc Pur pour les cartes
  static const Color lightBorder =
      Color(0xFFE2E8F0); // Slate 200 - Délimitation nette des cartes
  static const Color lightBorderHover = Color(0xFFCBD5E1); // Slate 300
  static const Color lightTextPrimary =
      Color(0xFF0F172A); // Noir d'encre Slate 900 (Contraste 16.5:1)
  static const Color lightTextSecondary =
      Color(0xFF475569); // Gris Ardoise Slate 600 (Contraste 7.2:1)
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Gris Slate 400

  // ---------------------------------------------------------------------------
  // 2. COLORS - DARK PALETTE (Midnight Obsidian & Titanium)
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF0B0F19); // Midnight Obsidian riche
  static const Color darkBgSubtle = Color(0xFF111827); // Slate 900
  static const Color darkSurface = Color(0xFF151D2E); // Surface Slate profond
  static const Color darkSurfaceHover = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF26334D); // Bordure visible et nette
  static const Color darkBorderHover = Color(0xFF3B4D71);
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Blanc éclatant
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextTertiary = Color(0xFF64748B); // Slate 500

  static const Color darkSuccessBg = Color(0x26059669);
  static const Color darkSuccessText = Color(0xFF34D399);

  static const Color darkWarningBg = Color(0x26D97706);
  static const Color darkWarningText = Color(0xFFFBBF24);

  static const Color darkErrorBg = Color(0x26DC2626);
  static const Color darkErrorText = Color(0xFFF87171);

  static const Color darkInfoBg = Color(0x260284C7);
  static const Color darkInfoText = Color(0xFF38BDF8);

  // ---------------------------------------------------------------------------
  // 3. GRADIENTS
  // ---------------------------------------------------------------------------
  static LinearGradient get primaryGradient => _currentPalette.primaryGradient;

  static LinearGradient get secondaryGradient =>
      _currentPalette.secondaryGradient;

  static LinearGradient get cardGradientUV => _currentPalette.cardGradientUV;

  static LinearGradient get cardGradientCredit =>
      _currentPalette.cardGradientCredit;

  static LinearGradient get cardGradientCash =>
      _currentPalette.cardGradientCash;

  static LinearGradient get cardGradientProfitUV =>
      _currentPalette.cardGradientProfitUV;

  static LinearGradient get cardGradientProfitCredit =>
      _currentPalette.cardGradientProfitCredit;

  static const LinearGradient surfaceGlassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------------------------------------------------------------------------
  // 4. SPACING GRID (Multiples of 4)
  // ---------------------------------------------------------------------------
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Minimum Touch Target Accessibility standard
  static const double minTouchTarget = 44.0;

  // ---------------------------------------------------------------------------
  // 5. BORDER RADIUS
  // ---------------------------------------------------------------------------
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2Xl = 24.0;
  static const double radius3Xl = 32.0;
  static const double radiusPill = 999.0;

  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadius2Xl = BorderRadius.circular(radius2Xl);
  static final BorderRadius borderRadius3Xl = BorderRadius.circular(radius3Xl);
  static final BorderRadius borderRadiusPill =
      BorderRadius.circular(radiusPill);

  // ---------------------------------------------------------------------------
  // 6. SHADOWS & ELEVATION
  // ---------------------------------------------------------------------------
  static List<BoxShadow> shadowSm(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x66000000) : const Color(0x0A0F172A),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> shadowMd(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x73000000) : const Color(0x120F172A),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: isDark ? const Color(0x40000000) : const Color(0x0A0F172A),
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowLg(bool isDark) => [
        BoxShadow(
          color: isDark ? const Color(0x8A000000) : const Color(0x140F172A),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: isDark ? const Color(0x4D000000) : const Color(0x0A0F172A),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> shadowGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ---------------------------------------------------------------------------
  // 7. TRANSITIONS & TIMING
  // ---------------------------------------------------------------------------
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;
  static const Curve curveBounce = Curves.easeOutBack;

  // ---------------------------------------------------------------------------
  // 8. TYPOGRAPHY HELPERS
  // ---------------------------------------------------------------------------
  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.75,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}
