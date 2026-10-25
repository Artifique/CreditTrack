import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import '../models/operation_phone_wallet_model.dart';
import '../models/profile_model.dart';
import '../models/transaction_model.dart';

class TransactionController {
  final _supabase = Supabase.instance.client;

  // Cache en mémoire partagé et synchronisé pour toute l'application (Dashboard, Historique, Rapports)
  static final List<TransactionModel> _allTransactions = [];
  static final StreamController<List<TransactionModel>> _txStreamController =
      StreamController<List<TransactionModel>>.broadcast();
  static RealtimeChannel? _realtimeChannel;
  static bool _isLoading = false;
  static bool _isLoaded = false;
  static String? _loadedUserId;

  /// Flux temps réel des transactions de l'utilisateur connecté sans AUCUNE limite (illimité).
  ///
  /// Ce flux effectue une pagination automatique par blocs de 1 000 pour récupérer
  /// l'intégralité des transactions de la base (même au-delà du plafond serveur PostgREST de 1000)
  /// et écoute les événements Realtime de Supabase (INSERT, UPDATE, DELETE).
  Stream<List<TransactionModel>> watchTransactions({String? merchantPhone}) async* {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      yield const [];
      return;
    }

    // Réinitialiser si l'utilisateur connecté a changé
    if (_loadedUserId != userId) {
      _allTransactions.clear();
      _isLoaded = false;
      _loadedUserId = userId;
      _setupRealtime(userId);
    }

    // Lancer le chargement complet sans limite si pas encore fait
    if (!_isLoaded && !_isLoading) {
      _loadAllTransactions(userId);
    }

    // Émettre immédiatement les données en cache
    if (_isLoaded) {
      yield _filterTransactions(_allTransactions, merchantPhone);
    }

    // Émettre à chaque mise à jour (insert, update, delete, refresh)
    await for (final list in _txStreamController.stream) {
      yield _filterTransactions(list, merchantPhone);
    }
  }

  static List<TransactionModel> _filterTransactions(List<TransactionModel> list, String? merchantPhone) {
    final phone = merchantPhone?.trim();
    if (phone != null && phone.isNotEmpty) {
      return list.where((t) => (t.merchantPhone ?? '').trim() == phone).toList();
    }
    return list;
  }

  static void _notify() {
    if (!_txStreamController.isClosed) {
      _txStreamController.add(List.unmodifiable(_allTransactions));
    }
  }

  /// Charge 100% des transactions par pagination transparente de 1 000 en 1 000
  static Future<void> _loadAllTransactions(String userId) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final supabase = Supabase.instance.client;
      final List<TransactionModel> all = [];
      const pageSize = 1000;
      int from = 0;

      while (true) {
        final response = await supabase
            .from('transactions')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(from, from + pageSize - 1);

        final chunk = (response as List)
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        all.addAll(chunk);

        if (chunk.length < pageSize) {
          break;
        }
        from += pageSize;
      }

      _allTransactions
        ..clear()
        ..addAll(all);
      _isLoaded = true;
      _loadedUserId = userId;
      _notify();
    } catch (e, st) {
      AppLogger.error('Erreur chargement transactions illimitées', e, st);
    } finally {
      _isLoading = false;
    }
  }

  /// Écoute les modifications temps réel de Supabase (INSERT, UPDATE, DELETE)
  static void _setupRealtime(String userId) {
    try {
      _realtimeChannel?.unsubscribe();
    } catch (_) {}

    final supabase = Supabase.instance.client;
    _realtimeChannel = supabase
        .channel('public:transactions:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newTx = TransactionModel.fromJson(payload.newRecord);
                _allTransactions.removeWhere((t) => t.id == newTx.id);
                _allTransactions.insert(0, newTx);
                _notify();
              } else if (payload.eventType == PostgresChangeEvent.update) {
                final updatedTx = TransactionModel.fromJson(payload.newRecord);
                final idx = _allTransactions.indexWhere((t) => t.id == updatedTx.id);
                if (idx != -1) {
                  _allTransactions[idx] = updatedTx;
                } else {
                  _allTransactions.insert(0, updatedTx);
                }
                _allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                _notify();
              } else if (payload.eventType == PostgresChangeEvent.delete) {
                final id = payload.oldRecord['id'] as String?;
                if (id != null) {
                  _allTransactions.removeWhere((t) => t.id == id);
                  _notify();
                }
              }
            } catch (e, st) {
              AppLogger.error('Erreur traitement realtime transaction', e, st);
            }
          },
        )
        .subscribe();
  }

  /// Recharge manuellement l'intégralité des transactions depuis le serveur
  Future<void> refreshTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _isLoading = false;
      await _loadAllTransactions(userId);
    }
  }

  static String mapTransactionError(Object e) {
    final s = e.toString();
    if (s.contains('SOLDE_INSUFFISANT')) {
      return 'Solde insuffisant : cette opération rendrait le solde négatif.';
    }
    if (s.contains('MERCHANT_PHONE_REQUIRED')) {
      return 'Le numéro de transfert est obligatoire pour enregistrer une transaction.';
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
    for (final r in rows as List<dynamic>) {
      final m = Map<String, dynamic>.from(r as Map);
      pu += (m['profit_uv'] as num?)?.toDouble() ?? 0;
      pc += (m['profit_credit'] as num?)?.toDouble() ?? 0;
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
      final created = TransactionModel.fromJson(response);
      _allTransactions.removeWhere((t) => t.id == created.id);
      _allTransactions.insert(0, created);
      _notify();
      return created;
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
      final updated = TransactionModel.fromJson((response as List).first as Map<String, dynamic>);
      final idx = _allTransactions.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        _allTransactions[idx] = updated;
      } else {
        _allTransactions.insert(0, updated);
      }
      _allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notify();
      return updated;
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
      _allTransactions.removeWhere((t) => t.id == transactionId);
      _notify();
    } catch (e, st) {
      AppLogger.error('Echec suppression transaction', e, st);
      throw Exception(mapTransactionError(e));
    }
  }

  /// Récupère les transactions (illimité par défaut avec pagination automatique pour dépasser le plafond serveur de 1000).
  Future<List<TransactionModel>> getTransactions({int? limit, String? merchantPhone}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    if (limit != null) {
      var q = _supabase.from('transactions').select().eq('user_id', userId);
      final p = merchantPhone?.trim();
      if (p != null && p.isNotEmpty) {
        q = q.eq('merchant_phone', p);
      }
      final response = await q.order('created_at', ascending: false).limit(limit);
      return (response as List).map((json) => TransactionModel.fromJson(json)).toList();
    }

    if (!_isLoaded) {
      await _loadAllTransactions(userId);
    }
    return _filterTransactions(_allTransactions, merchantPhone);
  }

  /// Numéros client déjà utilisés (les plus récents en premier, dédupliqués),
  /// pour suggestion automatique à la saisie d'une nouvelle transaction.
  Future<List<String>> getRecentClientPhones() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _supabase
        .from('transactions')
        .select('client_phone, type')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final seen = <String>{};
    final result = <String>[];
    for (final r in rows as List<dynamic>) {
      final m = Map<String, dynamic>.from(r as Map);
      if (m['type'] == 'transfert_profit_uv') continue;
      final phone = (m['client_phone'] as String?)?.trim() ?? '';
      if (phone.isEmpty || !seen.add(phone)) continue;
      result.add(phone);
    }
    return result;
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
