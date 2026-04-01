import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final _supabase = Supabase.instance.client;

  // Stream pour suivre l'état de l'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Connexion avec Email / Mot de passe
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception("Erreur de connexion : $e");
    }
  }

  // Inscription et création automatique du profil
  Future<AuthResponse> signUp(String email, String password, String businessName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'business_name': businessName},
      );
      return response;
    } catch (e) {
      throw Exception("Erreur d'inscription : $e");
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Récupérer l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;
}
