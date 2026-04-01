import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère la sélection du numéro d'opération (filtrage historique / stats) et la persistance locale.
class OperationPhoneController extends ChangeNotifier {
  OperationPhoneController._();
  static final instance = OperationPhoneController._();

  static const _prefKey = 'selected_operation_phone_v1';
  static const _allSentinel = '__ALL__';

  List<String> _phones = [];
  String? _selected;

  List<String> get registeredPhones => List.unmodifiable(_phones);

  /// `null` = tous les numéros ; sinon filtre sur ce numéro (colonne `merchant_phone`).
  String? get selectedForFilter => _selected;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw == _allSentinel || raw.isEmpty) {
      _selected = null;
    } else {
      _selected = raw;
    }
    notifyListeners();
  }

  /// À appeler après chargement du profil : liste des numéros enregistrés (max 3).
  Future<void> syncFromProfile(List<String> phones) async {
    _phones = phones
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .take(3)
        .toList();

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefKey)) {
      if (_phones.isNotEmpty) {
        _selected = _phones.first;
        await prefs.setString(_prefKey, _selected!);
      } else {
        _selected = null;
        await prefs.setString(_prefKey, _allSentinel);
      }
    } else {
      final saved = prefs.getString(_prefKey);
      if (saved == null || saved == _allSentinel || saved.isEmpty) {
        _selected = null;
      } else if (_phones.contains(saved)) {
        _selected = saved;
      } else {
        _selected = _phones.isNotEmpty ? _phones.first : null;
        await prefs.setString(_prefKey, _selected ?? _allSentinel);
      }
    }
    notifyListeners();
  }

  Future<void> selectAllNumbers() async {
    _selected = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _allSentinel);
    notifyListeners();
  }

  Future<void> selectPhone(String phone) async {
    if (!_phones.contains(phone)) return;
    _selected = phone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, phone);
    notifyListeners();
  }
}
