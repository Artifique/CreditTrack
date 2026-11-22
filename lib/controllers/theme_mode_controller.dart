import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_color_palette.dart';
import '../core/tokens.dart';

/// Contrôleur d'apparence globale de l'application :
/// - Mode d'affichage (Clair / Sombre)
/// - Palette de couleur active (5 thèmes personnalisables)
class ThemeModeController extends ChangeNotifier {
  ThemeModeController._();
  static final instance = ThemeModeController._();

  static const _prefDarkKey = 'app_theme_dark_v1';
  static const _prefPaletteKey = 'app_theme_palette_v1';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  AppPaletteId _paletteId = AppPaletteId.orange;
  AppPaletteId get paletteId => _paletteId;
  AppColorPalette get activePalette => AppColorPalette.get(_paletteId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_prefDarkKey) ?? false;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;

    final paletteStr = prefs.getString(_prefPaletteKey);
    final palette = AppColorPalette.fromString(paletteStr);
    _paletteId = palette.id;
    AppTokens.setPalette(palette);

    notifyListeners();
  }

  Future<void> setDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDarkKey, dark);
    notifyListeners();
  }

  Future<void> setPalette(AppPaletteId id) async {
    _paletteId = id;
    final palette = AppColorPalette.get(id);
    AppTokens.setPalette(palette);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPaletteKey, id.name);
    notifyListeners();
  }

  /// Synchronisation avec paramètres distants éventuels.
  Future<void> applyFromRemote(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDarkKey, dark);
    notifyListeners();
  }
}
