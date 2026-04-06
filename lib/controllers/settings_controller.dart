import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../models/business_settings_model.dart';
import '../models/operation_phone_wallet_model.dart';
import '../models/profile_model.dart';

class SettingsController {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<ProfileModel?> getProfile() async {
    final userId = _userId;
    if (userId == null) return null;

    AppLogger.info('Chargement profil user=$userId');
    final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  Future<OperationPhoneWalletModel?> getOperationPhoneWallet(String phone) async {
    final userId = _userId;
    if (userId == null) return null;
    final p = phone.trim();
    if (p.isEmpty) return null;
    final row = await _supabase
        .from('operation_phone_wallets')
        .select()
        .eq('user_id', userId)
        .eq('phone', p)
        .maybeSingle();
    if (row == null) {
      return OperationPhoneWalletModel(phone: p, soldeUv: 0, soldeCredit: 0, profitUv: 0, profitCredit: 0);
    }
    return OperationPhoneWalletModel.fromJson(row);
  }

  /// Met à jour les soldes UV / crédit du numéro (ne modifie pas les bénéfices cumulés).
  Future<void> setOperationPhoneBalances({
    required String phone,
    required double soldeUv,
    required double soldeCredit,
  }) async {
    if (_userId == null) throw Exception('Utilisateur non connecté.');
    await _supabase.rpc('set_operation_phone_balances', params: {
      'p_phone': phone.trim(),
      'p_solde_uv': soldeUv,
      'p_solde_credit': soldeCredit,
    });
  }

  Future<void> updateProfile({
    required String businessName,
    required String ownerName,
    required String phoneNumber,
    List<String>? operationPhones,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception("Utilisateur non connecté.");
    }

    final phones = (operationPhones ?? [])
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .take(3)
        .toList();

    AppLogger.info('Mise a jour profil user=$userId');
    await _supabase.from('profiles').upsert({
      'id': userId,
      'business_name': businessName,
      'owner_name': ownerName,
      'phone_number': phoneNumber,
      'operation_phones': phones,
    });
  }

  Future<BusinessSettingsModel> getBusinessSettings() async {
    final userId = _userId;
    if (userId == null) return BusinessSettingsModel.empty;

    try {
      AppLogger.info('Chargement settings user=$userId');
      final response = await _supabase
          .from('business_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return BusinessSettingsModel.empty;
      return BusinessSettingsModel.fromJson(response);
    } catch (e, st) {
      AppLogger.warn('Settings non disponibles, fallback valeurs par defaut');
      AppLogger.error('Erreur lecture business_settings', e, st);
      return BusinessSettingsModel.empty;
    }
  }

  Future<void> updateBusinessSettings({
    required bool darkMode,
    required String language,
    required bool autoPrintReceipt,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    AppLogger.info('Mise a jour settings user=$userId');
    await _supabase.from('business_settings').upsert({
      'user_id': userId,
      'dark_mode': darkMode,
      'language': language,
      'auto_print_receipt': autoPrintReceipt,
    });
  }
}
