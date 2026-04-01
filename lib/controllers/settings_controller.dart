import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_settings_model.dart';
import '../models/profile_model.dart';

class SettingsController {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<ProfileModel?> getProfile() async {
    final userId = _userId;
    if (userId == null) return null;

    final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  Future<void> updateProfile({
    required String businessName,
    required String ownerName,
    required String phoneNumber,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception("Utilisateur non connecté.");
    }

    await _supabase.from('profiles').upsert({
      'id': userId,
      'business_name': businessName,
      'owner_name': ownerName,
      'phone_number': phoneNumber,
    });
  }

  Future<BusinessSettingsModel> getBusinessSettings() async {
    final userId = _userId;
    if (userId == null) return BusinessSettingsModel.empty;

    try {
      final response = await _supabase
          .from('business_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return BusinessSettingsModel.empty;
      return BusinessSettingsModel.fromJson(response);
    } catch (_) {
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

    await _supabase.from('business_settings').upsert({
      'user_id': userId,
      'dark_mode': darkMode,
      'language': language,
      'auto_print_receipt': autoPrintReceipt,
    });
  }
}
