import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import '../models/profile_model.dart';
import '../models/transaction_model.dart';

class TransactionController {
  final _supabase = Supabase.instance.client;

  /// Flux temps réel des transactions de l'utilisateur connecté.
  /// Si [merchantPhone] est renseigné, seules les opérations faites avec ce numéro agent sont retournées.
  ///
  /// Note: l'API `.stream()` de Supabase n'autorise qu'un seul filtre `.eq()` ; le second filtre
  /// (`merchant_phone`) est donc appliqué côté client sur les données déjà filtrées par `user_id`.
  Stream<List<TransactionModel>> watchTransactions({String? merchantPhone}) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    final phone = merchantPhone?.trim();

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) {
          var list = data.map((json) => TransactionModel.fromJson(json)).toList();
          if (phone != null && phone.isNotEmpty) {
            list = list.where((t) => (t.merchantPhone ?? '').trim() == phone).toList();
          }
          return list;
        });
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
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      AppLogger.info('Insertion transaction ${transaction.type.name} user=${transaction.userId}');
      final response = await _supabase.from('transactions').insert(transaction.toJson()).select().single();
      return TransactionModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('Echec insertion transaction', e, st);
      throw Exception("Erreur lors de l'ajout de la transaction : $e");
    }
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("Session expirée. Reconnecte-toi.");
    }
    if (transaction.id == null) {
      throw Exception("Transaction invalide: identifiant manquant.");
    }

    try {
      final response = await _supabase.rpc('update_transaction', params: {
        'p_id': transaction.id,
        'p_user_id': userId,
        'p_type': transaction.toJson()['type'],
        'p_category': transaction.category.name,
        'p_client_name': transaction.clientName,
        'p_client_phone': transaction.clientPhone,
        'p_merchant_phone': transaction.merchantPhone,
        'p_amount': transaction.amount,
        'p_note': transaction.note,
      });
      return TransactionModel.fromJson((response as List).first as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error('Echec modification transaction', e, st);
      throw Exception("Erreur lors de la modification de la transaction : $e");
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("Session expirée. Reconnecte-toi.");
    }
    try {
      await _supabase.rpc('delete_transaction', params: {
        'p_id': transactionId,
        'p_user_id': userId,
      });
    } catch (e, st) {
      AppLogger.error('Echec suppression transaction', e, st);
      throw Exception("Erreur lors de la suppression de la transaction : $e");
    }
  }

  Future<List<TransactionModel>> getTransactions({int limit = 100, String? merchantPhone}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var q = _supabase.from('transactions').select().eq('user_id', userId);
    final p = merchantPhone?.trim();
    if (p != null && p.isNotEmpty) {
      q = q.eq('merchant_phone', p);
    }
    final response = await q.order('created_at', ascending: false).limit(limit);

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
