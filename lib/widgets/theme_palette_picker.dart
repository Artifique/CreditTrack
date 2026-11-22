import 'package:flutter/material.dart';
import '../controllers/theme_mode_controller.dart';
import '../core/app_color_palette.dart';
import '../core/tokens.dart';

/// Sélecteur de palettes de thèmes (5 couleurs au choix).
class ThemePalettePicker extends StatelessWidget {
  const ThemePalettePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: ThemeModeController.instance,
      builder: (context, _) {
        final currentId = ThemeModeController.instance.paletteId;

        return Column(
          children: AppColorPalette.palettes.map((p) {
            final isSelected = p.id == currentId;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: InkWell(
                onTap: () => ThemeModeController.instance.setPalette(p.id),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? p.primary500.withValues(alpha: 0.16)
                            : p.primary50)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? p.primary500
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Aperçu double couleur (Primaire + Secondaire)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [p.primary500, p.secondary500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: p.primary500.withValues(alpha: 0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.subtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppTokens.darkTextTertiary
                                    : AppTokens.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.primary500,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          child: const Text(
                            'Actif',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
