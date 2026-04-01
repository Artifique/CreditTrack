import 'package:supabase_flutter/supabase_flutter.dart';
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
  Future<Map<String, dynamic>> getProfileData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return response;
  }

  // Ajouter une nouvelle transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _supabase.from('transactions').insert(transaction.toJson());
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de la transaction : $e");
    }
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
