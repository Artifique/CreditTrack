import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import '../models/transaction_model.dart';

/// Contrôleur gérant la Caisse Espèce Universelle.
///
/// Assure l'équilibre automatique strict entre la monnaie électronique Orange Money (UV)
/// et l'argent liquide en caisse (Espèce) :
/// - Solde UV diminue (Dépôt, Nafama, Transfert C2C) -> Solde Espèce augmente du même montant.
/// - Solde UV augmente (Retrait, Transfert UV) -> Solde Espèce diminue du même montant.
/// - Universel et commun à toutes les cartes SIM et numéros de l'agent.
class CashBalanceController extends ChangeNotifier {
  static final CashBalanceController _instance =
      CashBalanceController._internal();
  static CashBalanceController get instance => _instance;
  CashBalanceController._internal();

  static const String _prefInitialCash = 'caisse_universelle_initial_cash';

  double _initialCash = 0.0;
  double _transactionsNetCash = 0.0;
  bool _isInitialized = false;

  /// Fond de caisse initial physique défini par l'agent
  double get initialCash => _initialCash;

  /// Impact cumulé de toutes les transactions Orange Money UV sur la caisse
  double get transactionsNetCash => _transactionsNetCash;

  /// Solde Espèce universel total en temps réel
  double get soldeEspece => _initialCash + _transactionsNetCash;

  /// Initialisation au démarrage de l'application
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _initialCash = prefs.getDouble(_prefInitialCash) ?? 0.0;

      // Tentative de lecture du profil Supabase si disponible
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final res = await Supabase.instance.client
              .from('profiles')
              .select('solde_espece')
              .eq('id', userId)
              .maybeSingle();
          if (res != null && res['solde_espece'] != null) {
            final dbCash = (res['solde_espece'] as num).toDouble();
            if (dbCash > 0 && _initialCash == 0) {
              _initialCash = dbCash;
              await prefs.setDouble(_prefInitialCash, dbCash);
            }
          }
        }
      } catch (_) {
        // Supabase non initialisé ou colonne non disponible
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Erreur initialisation CashBalanceController', e, st);
    }
  }

  /// Définit le fond de caisse initial
  Future<void> setInitialCash(double amount) async {
    _initialCash = amount;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefInitialCash, amount);

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'solde_espece': soldeEspece}).eq('id', userId);
        }
      } catch (_) {
        // Colonne optionnelle côté Supabase
      }
    } catch (e, st) {
      AppLogger.error('Erreur sauvegarde fond de caisse initial', e, st);
    }
    notifyListeners();
  }

  /// Ajuste le fond de caisse (ajout d'espèces ou retrait pour la banque)
  Future<void> adjustInitialCash(double delta) async {
    await setInitialCash(_initialCash + delta);
  }

  final Map<String, ({double before, double after})> _cashFlowMap = {};

  /// Protection du solde Espèce :
  /// Vérifie si le montant disponible en caisse est suffisant pour couvrir une sortie d'espèces.
  /// Ne jamais autoriser une opération qui ferait passer le solde en dessous de 0 FCFA.
  bool canAffordCashOut(double amount) {
    return soldeEspece >= amount;
  }

  String _transactionKey(TransactionModel tx) {
    if (tx.id != null && tx.id!.isNotEmpty) return tx.id!;
    return '${tx.createdAt.millisecondsSinceEpoch}_${tx.amount}_${tx.type.name}';
  }

  /// Recalcule en temps réel l'impact de toutes les transactions UV sur la caisse
  /// et enregistre le fil chronologique du solde espèce (avant et après) pour chaque opération.
  void syncWithTransactions(List<TransactionModel> allTransactions) {
    _cashFlowMap.clear();

    // Tri chronologique croissant pour reconstituer l'évolution exacte du solde liquide
    final sorted = List<TransactionModel>.from(allTransactions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double runningCash = _initialCash;

    for (final tx in sorted) {
      final delta = getCashDeltaForTransaction(tx);
      final before = runningCash;
      final after = runningCash + delta;
      runningCash = after;

      _cashFlowMap[_transactionKey(tx)] = (before: before, after: after);
    }

    _transactionsNetCash = runningCash - _initialCash;
    notifyListeners();
  }

  /// Retourne le solde Espèce avant et après pour une transaction donnée
  ({double before, double after}) getCashFlow(TransactionModel tx) {
    final key = _transactionKey(tx);
    if (_cashFlowMap.containsKey(key)) {
      return _cashFlowMap[key]!;
    }
    // Fallback pour transaction en cours de saisie ou non encore synchronisée
    final delta = getCashDeltaForTransaction(tx);
    final current = soldeEspece;
    return (before: current, after: current + delta);
  }

  /// Solde Espèce avant l'opération
  double getCashBefore(TransactionModel tx) => getCashFlow(tx).before;

  /// Solde Espèce après l'opération
  double getCashAfter(TransactionModel tx) => getCashFlow(tx).after;

  /// Calcule l'impact d'une transaction sur la caisse liquide :
  /// - Dépôt / Nafama / Transfert C2C : client donne du cash -> caisse + montant
  /// - Retrait / Transfert UV : agent donne du cash -> caisse - montant
  /// - Autres : 0
  static double getCashDeltaForTransaction(TransactionModel tx) {
    if (tx.category == TransactionCategory.UV) {
      switch (tx.type) {
        case TransactionType.depot:
        case TransactionType.nafama:
        case TransactionType.transfertC2c:
          return tx.amount;
        case TransactionType.retrait:
        case TransactionType.transfertUv:
          return -tx.amount;
        case TransactionType.transfertProfitUv:
          return 0.0;
        default:
          return 0.0;
      }
    }
    return 0.0;
  }
}
