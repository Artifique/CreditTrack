import 'package:flutter/material.dart';

/// Identifiants des 5 palettes de couleurs disponibles
enum AppPaletteId {
  orange,
  ocean,
  emerald,
  violet,
  ruby,
}

/// Définition complète d'une palette de couleur pour CreditTrack
class AppColorPalette {
  final AppPaletteId id;
  final String name;
  final String subtitle;
  final Color previewColor;

  // Nuances primaires (50 à 900)
  final Color primary50;
  final Color primary100;
  final Color primary200;
  final Color primary300;
  final Color primary400;
  final Color primary500;
  final Color primary600;
  final Color primary700;
  final Color primary800;
  final Color primary900;

  // Nuances secondaires (Gains, commissions, contrastes)
  final Color secondary50;
  final Color secondary100;
  final Color secondary200;
  final Color secondary300;
  final Color secondary400;
  final Color secondary500;
  final Color secondary600;
  final Color secondary700;

  // Gradients spécifiques pour les cartes de solde et KPIs du Dashboard
  final LinearGradient cardGradientUV;
  final LinearGradient cardGradientCredit;
  final LinearGradient cardGradientCash;
  final LinearGradient cardGradientProfitUV;
  final LinearGradient cardGradientProfitCredit;

  const AppColorPalette({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.previewColor,
    required this.primary50,
    required this.primary100,
    required this.primary200,
    required this.primary300,
    required this.primary400,
    required this.primary500,
    required this.primary600,
    required this.primary700,
    required this.primary800,
    required this.primary900,
    required this.secondary50,
    required this.secondary100,
    required this.secondary200,
    required this.secondary300,
    required this.secondary400,
    required this.secondary500,
    required this.secondary600,
    required this.secondary700,
    required this.cardGradientUV,
    required this.cardGradientCredit,
    required this.cardGradientCash,
    required this.cardGradientProfitUV,
    required this.cardGradientProfitCredit,
  });

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary500, primary600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => LinearGradient(
        colors: [secondary500, secondary600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // 1. Orange Solaire (Télécom / Orange Money)
  static const orange = AppColorPalette(
    id: AppPaletteId.orange,
    name: 'Orange Solaire',
    subtitle: 'Identité classique Caisse & Télécom',
    previewColor: Color(0xFFFF6600),
    primary50: Color(0xFFFFF7ED),
    primary100: Color(0xFFFFEDD5),
    primary200: Color(0xFFFED7AA),
    primary300: Color(0xFFFDBA74),
    primary400: Color(0xFFFB923C),
    primary500: Color(0xFFFF6600),
    primary600: Color(0xFFEA580C),
    primary700: Color(0xFFC2410C),
    primary800: Color(0xFF9A3412),
    primary900: Color(0xFF7C2D12),
    secondary50: Color(0xFFF0FDF4),
    secondary100: Color(0xFFDCFCE7),
    secondary200: Color(0xFFBBF7D0),
    secondary300: Color(0xFF86EFAC),
    secondary400: Color(0xFF34D399),
    secondary500: Color(0xFF059669),
    secondary600: Color(0xFF047857),
    secondary700: Color(0xFF064E3B),
    cardGradientUV: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCredit: LinearGradient(
      colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCash: LinearGradient(
      colors: [Color(0xFF047857), Color(0xFF0F766E), Color(0xFF14B8A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitUV: LinearGradient(
      colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitCredit: LinearGradient(
      colors: [Color(0xFF7C2D12), Color(0xFFFF6600)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // 2. Bleu Océan (Fintech Pro & Wave)
  static const ocean = AppColorPalette(
    id: AppPaletteId.ocean,
    name: 'Bleu Océan',
    subtitle: 'Moderne, professionnel et calme',
    previewColor: Color(0xFF0284C7),
    primary50: Color(0xFFF0F9FF),
    primary100: Color(0xFFE0F2FE),
    primary200: Color(0xFFBAE6FD),
    primary300: Color(0xFF7DD3FC),
    primary400: Color(0xFF38BDF8),
    primary500: Color(0xFF0284C7),
    primary600: Color(0xFF0369A1),
    primary700: Color(0xFF075985),
    primary800: Color(0xFF0C4A6E),
    primary900: Color(0xFF082F49),
    secondary50: Color(0xFFF0FDF4),
    secondary100: Color(0xFFDCFCE7),
    secondary200: Color(0xFFBBF7D0),
    secondary300: Color(0xFF86EFAC),
    secondary400: Color(0xFF34D399),
    secondary500: Color(0xFF10B981),
    secondary600: Color(0xFF059669),
    secondary700: Color(0xFF047857),
    cardGradientUV: LinearGradient(
      colors: [Color(0xFF0C4A6E), Color(0xFF075985)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCredit: LinearGradient(
      colors: [Color(0xFF065F46), Color(0xFF0D9488), Color(0xFF14B8A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCash: LinearGradient(
      colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitUV: LinearGradient(
      colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitCredit: LinearGradient(
      colors: [Color(0xFF1E3A8A), Color(0xFF38BDF8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // 3. Vert Émeraude (Croissance & Cash)
  static const emerald = AppColorPalette(
    id: AppPaletteId.emerald,
    name: 'Vert Émeraude',
    subtitle: 'Finances, croissance et abondance',
    previewColor: Color(0xFF059669),
    primary50: Color(0xFFECFDF5),
    primary100: Color(0xFFD1FAE5),
    primary200: Color(0xFFA7F3D0),
    primary300: Color(0xFF6EE7B7),
    primary400: Color(0xFF34D399),
    primary500: Color(0xFF059669),
    primary600: Color(0xFF047857),
    primary700: Color(0xFF065F46),
    primary800: Color(0xFF064E3B),
    primary900: Color(0xFF022C22),
    secondary50: Color(0xFFFFFBEB),
    secondary100: Color(0xFFFEF3C7),
    secondary200: Color(0xFFFDE68A),
    secondary300: Color(0xFFFCD34D),
    secondary400: Color(0xFFFBBF24),
    secondary500: Color(0xFFD97706),
    secondary600: Color(0xFFB45309),
    secondary700: Color(0xFF78350F),
    cardGradientUV: LinearGradient(
      colors: [Color(0xFF022C22), Color(0xFF064E3B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCredit: LinearGradient(
      colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCash: LinearGradient(
      colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF2DD4BF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitUV: LinearGradient(
      colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitCredit: LinearGradient(
      colors: [Color(0xFF065F46), Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // 4. Violet Royal (Prestige & Business)
  static const violet = AppColorPalette(
    id: AppPaletteId.violet,
    name: 'Violet Royal',
    subtitle: 'Élégant, premium et distingué',
    previewColor: Color(0xFF7C3AED),
    primary50: Color(0xFFF5F3FF),
    primary100: Color(0xFFEDE9FE),
    primary200: Color(0xFFDDD6FE),
    primary300: Color(0xFFC4B5FD),
    primary400: Color(0xFFA78BFA),
    primary500: Color(0xFF7C3AED),
    primary600: Color(0xFF6D28D9),
    primary700: Color(0xFF5B21B6),
    primary800: Color(0xFF4C1D95),
    primary900: Color(0xFF2E1065),
    secondary50: Color(0xFFFDF2F8),
    secondary100: Color(0xFFFCE7F3),
    secondary200: Color(0xFFFBCFE8),
    secondary300: Color(0xFFF472B6),
    secondary400: Color(0xFFEC4899),
    secondary500: Color(0xFFDB2777),
    secondary600: Color(0xFFBE185D),
    secondary700: Color(0xFF9D174D),
    cardGradientUV: LinearGradient(
      colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCredit: LinearGradient(
      colors: [Color(0xFF831843), Color(0xFF9D174D), Color(0xFFDB2777)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCash: LinearGradient(
      colors: [Color(0xFF047857), Color(0xFF0D9488), Color(0xFF14B8A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitUV: LinearGradient(
      colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitCredit: LinearGradient(
      colors: [Color(0xFF5B21B6), Color(0xFFA78BFA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // 5. Rouge Rubis (Énergie & Puissance)
  static const ruby = AppColorPalette(
    id: AppPaletteId.ruby,
    name: 'Rouge Rubis',
    subtitle: 'Dynamique, percutant et énergique',
    previewColor: Color(0xFFE11D48),
    primary50: Color(0xFFFFF1F2),
    primary100: Color(0xFFFFE4E6),
    primary200: Color(0xFFFECDD3),
    primary300: Color(0xFFFDA4AF),
    primary400: Color(0xFFFB7185),
    primary500: Color(0xFFE11D48),
    primary600: Color(0xFFBE123C),
    primary700: Color(0xFF9F1239),
    primary800: Color(0xFF881337),
    primary900: Color(0xFF4C0519),
    secondary50: Color(0xFFF0F9FF),
    secondary100: Color(0xFFE0F2FE),
    secondary200: Color(0xFFBAE6FD),
    secondary300: Color(0xFF7DD3FC),
    secondary400: Color(0xFF38BDF8),
    secondary500: Color(0xFF0284C7),
    secondary600: Color(0xFF0369A1),
    secondary700: Color(0xFF075985),
    cardGradientUV: LinearGradient(
      colors: [Color(0xFF4C0519), Color(0xFF881337)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCredit: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientCash: LinearGradient(
      colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitUV: LinearGradient(
      colors: [Color(0xFF9F1239), Color(0xFFE11D48)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradientProfitCredit: LinearGradient(
      colors: [Color(0xFF881337), Color(0xFFFB7185)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const List<AppColorPalette> palettes = [
    orange,
    ocean,
    emerald,
    violet,
    ruby,
  ];

  static AppColorPalette get(AppPaletteId id) {
    switch (id) {
      case AppPaletteId.orange:
        return orange;
      case AppPaletteId.ocean:
        return ocean;
      case AppPaletteId.emerald:
        return emerald;
      case AppPaletteId.violet:
        return violet;
      case AppPaletteId.ruby:
        return ruby;
    }
  }

  static AppColorPalette fromString(String? key) {
    if (key == null) return orange;
    return palettes.firstWhere(
      (p) => p.id.name.toLowerCase() == key.toLowerCase(),
      orElse: () => orange,
    );
  }
}
