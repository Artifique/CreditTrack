import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sim_card_model.dart';
import 'operation_phone_controller.dart';
import 'settings_controller.dart';

/// Manages dynamic SIM cards with custom names, real-time balances, and unlimited scaling.
class SimCardController extends ChangeNotifier {
  SimCardController._();
  static final instance = SimCardController._();

  static const _namesPrefKey = 'sim_cards_custom_names_v1';
  final _supabase = Supabase.instance.client;
  final _settingsController = SettingsController();

  List<SimCardModel> _simCards = [];
  List<SimCardModel> get simCards => List.unmodifiable(_simCards);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Loads all SIM cards from user's operation_phones and fetches their real-time balances
  Future<List<SimCardModel>> loadSimCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _settingsController.getProfile();
      final phones = profile?.operationPhones ?? [];

      final prefs = await SharedPreferences.getInstance();
      final namesJson = prefs.getString(_namesPrefKey);
      Map<String, String> namesMap = {};
      if (namesJson != null) {
        try {
          final decoded = jsonDecode(namesJson) as Map<String, dynamic>;
          namesMap = decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {}
      }

      final List<SimCardModel> loaded = [];
      for (int i = 0; i < phones.length; i++) {
        final phone = phones[i].trim();
        if (phone.isEmpty) continue;

        final wallet = await _settingsController.getOperationPhoneWallet(phone);
        final defaultName = "SIM ${i + 1}";
        final customName = namesMap[phone] ?? defaultName;

        loaded.add(SimCardModel(
          phone: phone,
          name: customName,
          soldeUv: wallet?.soldeUv ?? 0.0,
          soldeCredit: wallet?.soldeCredit ?? 0.0,
        ));
      }

      _simCards = loaded;
      return _simCards;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new SIM card with custom name, phone number, and optional initial balances.
  /// No limit on how many SIMs can be added!
  Future<SimCardModel> addSimCard({
    required String phone,
    required String name,
    double initialUv = 0.0,
    double initialCredit = 0.0,
  }) async {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final cleanName = name.trim().isNotEmpty ? name.trim() : "SIM $cleanPhone";

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("Session expirée. Veuillez vous reconnecter.");
    }

    // 1. Get current phones and append new one if not already present
    final profile = await _settingsController.getProfile();
    final currentPhones = List<String>.from(profile?.operationPhones ?? []);
    if (!currentPhones.contains(cleanPhone)) {
      currentPhones.add(cleanPhone);
      await _settingsController.updateProfile(
        businessName: profile?.businessName ?? "Mon Commerce",
        ownerName: profile?.ownerName ?? "",
        phoneNumber: profile?.phoneNumber ?? "",
        operationPhones: currentPhones,
      );
    }

    // 2. Set custom name in persistent storage
    final prefs = await SharedPreferences.getInstance();
    final namesJson = prefs.getString(_namesPrefKey);
    Map<String, String> namesMap = {};
    if (namesJson != null) {
      try {
        final decoded = jsonDecode(namesJson) as Map<String, dynamic>;
        namesMap = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    namesMap[cleanPhone] = cleanName;
    await prefs.setString(_namesPrefKey, jsonEncode(namesMap));

    // 3. Set initial balances if provided
    if (initialUv > 0 || initialCredit > 0) {
      try {
        await _settingsController.setOperationPhoneBalances(
          phone: cleanPhone,
          soldeUv: initialUv,
          soldeCredit: initialCredit,
        );
      } catch (_) {
        // Balances will default to 0 if table row wasn't ready
      }
    }

    // 4. Update OperationPhoneController to know about the new phone
    await OperationPhoneController.instance.syncFromProfile(currentPhones);

    // 5. Reload cards and notify
    final newSim = SimCardModel(
      phone: cleanPhone,
      name: cleanName,
      soldeUv: initialUv,
      soldeCredit: initialCredit,
    );

    await loadSimCards();
    return newSim;
  }

  /// Get a single SIM card model by its phone number
  SimCardModel? getSim(String phone) {
    try {
      return _simCards.firstWhere((s) => s.phone == phone.trim());
    } catch (_) {
      return null;
    }
  }

  /// Updates a SIM card's display name and optional balances
  Future<void> updateSimCard({
    required String phone,
    required String newName,
    double? soldeUv,
    double? soldeCredit,
  }) async {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final cleanName = newName.trim().isNotEmpty ? newName.trim() : "SIM $cleanPhone";

    final prefs = await SharedPreferences.getInstance();
    final namesJson = prefs.getString(_namesPrefKey);
    Map<String, String> namesMap = {};
    if (namesJson != null) {
      try {
        final decoded = jsonDecode(namesJson) as Map<String, dynamic>;
        namesMap = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    namesMap[cleanPhone] = cleanName;
    await prefs.setString(_namesPrefKey, jsonEncode(namesMap));

    if (soldeUv != null || soldeCredit != null) {
      try {
        await _settingsController.setOperationPhoneBalances(
          phone: cleanPhone,
          soldeUv: soldeUv ?? 0.0,
          soldeCredit: soldeCredit ?? 0.0,
        );
      } catch (_) {}
    }

    await loadSimCards();
  }

  /// Removes a SIM card from user's operation phones
  Future<void> deleteSimCard(String phone) async {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final profile = await _settingsController.getProfile();
    final currentPhones = List<String>.from(profile?.operationPhones ?? []);
    currentPhones.remove(cleanPhone);

    await _settingsController.updateProfile(
      businessName: profile?.businessName ?? "Mon Commerce",
      ownerName: profile?.ownerName ?? "",
      phoneNumber: profile?.phoneNumber ?? "",
      operationPhones: currentPhones,
    );

    final prefs = await SharedPreferences.getInstance();
    final namesJson = prefs.getString(_namesPrefKey);
    if (namesJson != null) {
      try {
        final decoded = jsonDecode(namesJson) as Map<String, dynamic>;
        final namesMap = decoded.map((k, v) => MapEntry(k, v.toString()));
        namesMap.remove(cleanPhone);
        await prefs.setString(_namesPrefKey, jsonEncode(namesMap));
      } catch (_) {}
    }

    await OperationPhoneController.instance.syncFromProfile(currentPhones);
    await loadSimCards();
  }
}
