import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème clair/sombre : préférences locales + alignement avec `business_settings.dark_mode`.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController._();
  static final instance = ThemeModeController._();

  static const _prefKey = 'app_theme_dark_v1';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_prefKey) ?? false;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, dark);
    notifyListeners();
  }

  /// À appeler après chargement Supabase (ex. tableau de bord).
  Future<void> applyFromRemote(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, dark);
    notifyListeners();
  }
}
