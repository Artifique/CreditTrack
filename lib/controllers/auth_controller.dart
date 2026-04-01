import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';

class AuthController {
  final _supabase = Supabase.instance.client;

  // Stream pour suivre l'état de l'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Connexion avec Email / Mot de passe
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      AppLogger.info('Tentative de connexion pour $email');
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e, st) {
      AppLogger.error('Echec connexion utilisateur', e, st);
      throw Exception("Erreur de connexion : $e");
    }
  }

  // Inscription et création automatique du profil
  Future<AuthResponse> signUp(
    String email,
    String password,
    String businessName, {
    String? ownerName,
  }) async {
    try {
      AppLogger.info('Tentative inscription pour $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'business_name': businessName,
          if (ownerName != null && ownerName.trim().isNotEmpty) 'owner_name': ownerName.trim(),
        },
      );
      return response;
    } catch (e, st) {
      AppLogger.error('Echec inscription utilisateur', e, st);
      throw Exception("Erreur d'inscription : $e");
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    AppLogger.info('Déconnexion utilisateur');
    await _supabase.auth.signOut();
  }

  // Récupérer l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;
}
