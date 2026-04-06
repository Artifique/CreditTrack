import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import '../models/operation_phone_wallet_model.dart';
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
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  static String mapTransactionError(Object e) {
    final s = e.toString();
    if (s.contains('SOLDE_INSUFFISANT')) {
      return 'Solde insuffisant : cette opération rendrait le solde négatif.';
    }
    if (s.contains('MERCHANT_PHONE_REQUIRED')) {
      return 'Le numéro d’opération est obligatoire pour enregistrer une transaction.';
    }
    if (s.contains('Montant supérieur au bénéfice UV')) {
      return 'Montant supérieur au bénéfice UV disponible sur ce numéro.';
    }
    if (s.contains('Les soldes ne peuvent pas être négatifs')) {
      return 'Les soldes saisis ne peuvent pas être négatifs.';
    }
    return s;
  }

  /// Vue des soldes / bénéfices : par [merchantPhone] si renseigné, sinon totaux profil + somme des bénéfices.
  Future<OperationPhoneWalletModel> getWalletViewForFilter({String? merchantPhone}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return OperationPhoneWalletModel.empty;

    final phone = merchantPhone?.trim();
    if (phone != null && phone.isNotEmpty) {
      final row = await _supabase
          .from('operation_phone_wallets')
          .select()
          .eq('user_id', userId)
          .eq('phone', phone)
          .maybeSingle();
      if (row == null) {
        return OperationPhoneWalletModel(phone: phone, soldeUv: 0, soldeCredit: 0, profitUv: 0, profitCredit: 0);
      }
      return OperationPhoneWalletModel.fromJson(row);
    }

    final profile = await getProfileData();
    final rows = await _supabase.from('operation_phone_wallets').select('profit_uv, profit_credit').eq('user_id', userId);

    var pu = 0.0;
    var pc = 0.0;
    if (rows is List) {
      for (final r in rows) {
        final m = r as Map<String, dynamic>;
        pu += (m['profit_uv'] as num?)?.toDouble() ?? 0;
        pc += (m['profit_credit'] as num?)?.toDouble() ?? 0;
      }
    }

    return OperationPhoneWalletModel(
      phone: '',
      soldeUv: profile?.soldeUv ?? 0,
      soldeCredit: profile?.soldeCredit ?? 0,
      profitUv: pu,
      profitCredit: pc,
    );
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
      throw Exception(mapTransactionError(e));
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
      throw Exception(mapTransactionError(e));
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
      throw Exception(mapTransactionError(e));
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
