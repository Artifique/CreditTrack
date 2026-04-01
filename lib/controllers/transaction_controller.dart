import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/transaction_model.dart';

class TransactionController {
  final _supabase = Supabase.instance.client;

  // Stream pour écouter les transactions en temps réel
  Stream<List<TransactionModel>> get transactionStream {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  // Récupérer le profil (et donc les soldes) de l'utilisateur
  Future<ProfileModel?> getProfileData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return ProfileModel.fromJson(response);
  }

  // Ajouter une nouvelle transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _supabase.from('transactions').insert(transaction.toJson());
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de la transaction : $e");
    }
  }

  Future<List<TransactionModel>> getTransactions({int limit = 100}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => TransactionModel.fromJson(json)).toList();
  }

  // Calculer les statistiques simples pour le dashboard
  double calculateTotalDaily(List<TransactionModel> transactions, TransactionType type) {
    final today = DateTime.now();
    return transactions
        .where((t) => 
          t.type == type && 
          t.createdAt.day == today.day && 
          t.createdAt.month == today.month && 
          t.createdAt.year == today.year)
        .fold(0, (sum, t) => sum + t.amount);
  }
}
