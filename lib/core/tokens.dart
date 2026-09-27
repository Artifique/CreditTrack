import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System Tokens for CreditTrak
/// Standardized Design Tokens matching src/styles/tokens.css
class AppTokens {
  AppTokens._();

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 1. COLORS - LIGHT PALETTE (Orange Solaire & Noir Obsidian - Orange Money Pro)
  // ---------------------------------------------------------------------------
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF4F46E5); // Indigo vif
  static const Color primary600 = Color(0xFF4338CA); 
  static const Color primary700 = Color(0xFF3730A3);
  static const Color primary800 = Color(0xFF312E81);
  static const Color primary900 = Color(0xFF1E1B4B);

  static const Color secondary50 = Color(0xFFF0FDF4);
  static const Color secondary100 = Color(0xFFDCFCE7);
  static const Color secondary200 = Color(0xFFBBF7D0);
  static const Color secondary300 = Color(0xFF86EFAC);
  static const Color secondary400 = Color(0xFF4ADE80);
  static const Color secondary500 = Color(0xFF10B981); // Emerald (Nafama/Gain)
  static const Color secondary600 = Color(0xFF059669);
  static const Color secondary700 = Color(0xFF047857);

  // Semantics
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF065F46);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFF92400E);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorText = Color(0xFF991B1B);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoText = Color(0xFF0369A1);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Quick aliases
  static const Color primary = primary500;
  static const Color secondary = secondary500;

  // Light Mode Neutrals (Obsidian & Crisp Whites for Maximum Readability)
  static const Color lightBg = Color(0xFFF9FAFB);         // Gray 50
  static const Color lightBgSubtle = Color(0xFFF3F4F6);   // Gray 100
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);      // Gray 200
  static const Color lightBorderHover = Color(0xFFD1D5DB); // Gray 300
  static const Color lightTextPrimary = Color(0xFF111827); // Obsidian Gray 900
  static const Color lightTextSecondary = Color(0xFF4B5563); // Gray 600
  static const Color lightTextTertiary = Color(0xFF9CA3AF);  // Gray 400

  // ---------------------------------------------------------------------------
  // 2. COLORS - DARK PALETTE (Obsidian Night, Deep Charcoal)
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF0B0F17);           // Midnight Obsidian
  static const Color darkBgSubtle = Color(0xFF111827);     // Slate 900
  static const Color darkSurface = Color(0xFF1A2234);      // Slate 800
  static const Color darkSurfaceHover = Color(0xFF243048);
  static const Color darkBorder = Color(0xFF2E3A52);       // Slate 700
  static const Color darkBorderHover = Color(0xFF3E4D6C);  // Slate 600
  static const Color darkTextPrimary = Color(0xFFF9FAFB);  // Gray 50
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Gray 400
  static const Color darkTextTertiary = Color(0xFF6B7280);  // Gray 500

  static const Color darkSuccessBg = Color(0x2610B981);
  static const Color darkSuccessText = Color(0xFF34D399);

  static const Color darkWarningBg = Color(0x26F59E0B);
  static const Color darkWarningText = Color(0xFFFBBF24);

  static const Color darkErrorBg = Color(0x26EF4444);
  static const Color darkErrorText = Color(0xFFF87171);

  static const Color darkInfoBg = Color(0x260284C7);
  static const Color darkInfoText = Color(0xFF38BDF8);

  // ---------------------------------------------------------------------------
  // 3. GRADIENTS
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientUV = LinearGradient(
    colors: [Color(0xFF18181B), Color(0xFF27272A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientCredit = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

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
