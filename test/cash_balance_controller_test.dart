import 'package:credit_trak/controllers/cash_balance_controller.dart';
import 'package:credit_trak/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CashBalanceController Tests - Option Espèce Universelle', () {
    test('Dépôt UV augmente le solde Espèce du même montant', () {
      final ctrl = CashBalanceController.instance;
      final tx = TransactionModel(
        id: 'tx1',
        userId: 'user1',
        type: TransactionType.depot,
        category: TransactionCategory.UV,
        clientName: 'Client 1',
        clientPhone: '70000001',
        merchantPhone: '72000001',
        amount: 25000,
        commission: 35,
        soldeApres: 75000,
        createdAt: DateTime.now(),
      );

      final delta = CashBalanceController.getCashDeltaForTransaction(tx);
      expect(delta, 25000.0);

      ctrl.syncWithTransactions([tx]);
      expect(ctrl.transactionsNetCash, 25000.0);
    });

    test('Retrait UV diminue le solde Espèce du même montant', () {
      final ctrl = CashBalanceController.instance;
      final tx = TransactionModel(
        id: 'tx2',
        userId: 'user1',
        type: TransactionType.retrait,
        category: TransactionCategory.UV,
        clientName: 'Client 2',
        clientPhone: '70000002',
        merchantPhone: '72000002',
        amount: 10000,
        commission: 28,
        soldeApres: 110000,
        createdAt: DateTime.now(),
      );

      final delta = CashBalanceController.getCashDeltaForTransaction(tx);
      expect(delta, -10000.0);

      ctrl.syncWithTransactions([tx]);
      expect(ctrl.transactionsNetCash, -10000.0);
    });

    test('Synchronisation universelle multi-SIM et équilibre global', () async {
      final ctrl = CashBalanceController.instance;
      await ctrl.init();
      await ctrl.setInitialCash(100000.0); // Fond de caisse initial : 100 000 F

      final txList = [
        // SIM 1 : Dépôt 30 000 F (Solde UV SIM 1 diminue de 30 000, Caisse reçoit +30 000)
        TransactionModel(
          id: '1',
          userId: 'u',
          type: TransactionType.depot,
          category: TransactionCategory.UV,
          clientName: 'C1',
          clientPhone: '71111111',
          merchantPhone: 'SIM_1',
          amount: 30000,
          commission: 42,
          soldeApres: 70000,
          createdAt: DateTime.now(),
        ),
        // SIM 2 : Retrait 50 000 F (Solde UV SIM 2 augmente de 50 000, Caisse sort -50 000)
        TransactionModel(
          id: '2',
          userId: 'u',
          type: TransactionType.retrait,
          category: TransactionCategory.UV,
          clientName: 'C2',
          clientPhone: '72222222',
          merchantPhone: 'SIM_2',
          amount: 50000,
          commission: 140,
          soldeApres: 150000,
          createdAt: DateTime.now(),
        ),
        // SIM 3 : Nafama 10 000 F (Solde UV SIM 3 diminue de 10 000, Caisse reçoit +10 000)
        TransactionModel(
          id: '3',
          userId: 'u',
          type: TransactionType.nafama,
          category: TransactionCategory.UV,
          clientName: 'C3',
          clientPhone: '73333333',
          merchantPhone: 'SIM_3',
          amount: 10000,
          commission: 455,
          soldeApres: 40000,
          createdAt: DateTime.now(),
        ),
      ];

      ctrl.syncWithTransactions(txList);

      // Net transactions cash = +30 000 - 50 000 + 10 000 = -10 000
      expect(ctrl.transactionsNetCash, -10000.0);
      // Solde Espèce universel = 100 000 (initial) - 10 000 (net) = 90 000 CFA
      expect(ctrl.soldeEspece, 90000.0);
    });

    test('Protection solde Espèce : canAffordCashOut bloque si insuffisant',
        () async {
      final ctrl = CashBalanceController.instance;
      await ctrl.init();
      await ctrl.setInitialCash(15000.0);
      ctrl.syncWithTransactions([]);

      expect(ctrl.soldeEspece, 15000.0);
      // Opération de 10 000 F autorisée
      expect(ctrl.canAffordCashOut(10000.0), isTrue);
      // Opération de 15 000 F autorisée (solde devient 0)
      expect(ctrl.canAffordCashOut(15000.0), isTrue);
      // Opération de 20 000 F BLOQUÉE car solde deviendrait négatif (-5000 F)
      expect(ctrl.canAffordCashOut(20000.0), isFalse);
    });

    test(
        'Annulation / Suppression rétablit exactement le solde sans double comptage',
        () async {
      final ctrl = CashBalanceController.instance;
      await ctrl.init();
      await ctrl.setInitialCash(50000.0);

      final tx1 = TransactionModel(
        id: 't1',
        userId: 'u',
        type: TransactionType.depot,
        category: TransactionCategory.UV,
        clientName: 'C1',
        clientPhone: '71000001',
        amount: 20000,
        commission: 28,
        soldeApres: 80000,
        createdAt: DateTime.now(),
      );

      final tx2 = TransactionModel(
        id: 't2',
        userId: 'u',
        type: TransactionType.retrait,
        category: TransactionCategory.UV,
        clientName: 'C2',
        clientPhone: '71000002',
        amount: 30000,
        commission: 84,
        soldeApres: 110000,
        createdAt: DateTime.now(),
      );

      // Deux transactions : Solde = 50 000 + 20 000 - 30 000 = 40 000 F
      ctrl.syncWithTransactions([tx1, tx2]);
      expect(ctrl.soldeEspece, 40000.0);

      // Annulation de tx2 (Retrait) -> Rétablissement du solde à 50 000 + 20 000 = 70 000 F
      ctrl.syncWithTransactions([tx1]);
      expect(ctrl.soldeEspece, 70000.0);

      // Annulation de tx1 (Dépôt) -> Rétablissement du solde initial strict = 50 000 F
      ctrl.syncWithTransactions([]);
      expect(ctrl.soldeEspece, 50000.0);
    });

    test(
        'Historique des transactions : solde avant et solde après calculés chronologiquement',
        () async {
      final ctrl = CashBalanceController.instance;
      await ctrl.init();
      await ctrl.setInitialCash(100000.0); // Fond initial = 100 000 F

      final t0 = DateTime(2026, 11, 22, 10, 0);
      final t1 = DateTime(2026, 11, 22, 11, 0);
      final t2 = DateTime(2026, 11, 22, 12, 0);
      final t3 = DateTime(2026, 11, 22, 13, 0);

      final tx1 = TransactionModel(
        id: 'tx_depot_1',
        userId: 'u',
        type: TransactionType.depot,
        category: TransactionCategory.UV,
        clientName: 'Client Depot',
        clientPhone: '71000001',
        amount: 25000, // Caisse +25 000
        commission: 35,
        soldeApres: 75000,
        createdAt: t0,
      );

      final tx2 = TransactionModel(
        id: 'tx_retrait_1',
        userId: 'u',
        type: TransactionType.retrait,
        category: TransactionCategory.UV,
        clientName: 'Client Retrait',
        clientPhone: '71000002',
        amount: 15000, // Caisse -15 000
        commission: 42,
        soldeApres: 90000,
        createdAt: t1,
      );

      final tx3 = TransactionModel(
        id: 'tx_credit_1',
        userId: 'u',
        type: TransactionType.achat,
        category: TransactionCategory.CREDIT,
        clientName: 'Client Credit',
        clientPhone: '71000003',
        amount: 5000, // Crédit -> aucun impact caisse
        commission: 0,
        soldeApres: 15000,
        createdAt: t2,
      );

      final tx4 = TransactionModel(
        id: 'tx_retrait_2',
        userId: 'u',
        type: TransactionType.retrait,
        category: TransactionCategory.UV,
        clientName: 'Client Retrait 2',
        clientPhone: '71000004',
        amount: 30000, // Caisse -30 000
        commission: 84,
        soldeApres: 120000,
        createdAt: t3,
      );

      // On synchronise dans un ordre quelconque pour vérifier le tri chronologique
      ctrl.syncWithTransactions([tx4, tx2, tx1, tx3]);

      // Tx1 (Dépôt 25 000) : Avant = 100 000 F, Après = 125 000 F
      expect(tx1.soldeEspeceAvant, 100000.0);
      expect(tx1.soldeEspeceApres, 125000.0);

      // Tx2 (Retrait 15 000) : Avant = 125 000 F, Après = 110 000 F
      expect(tx2.soldeEspeceAvant, 125000.0);
      expect(tx2.soldeEspeceApres, 110000.0);

      // Tx3 (Crédit, sans mouvement caisse) : Avant = 110 000 F, Après = 110 000 F
      expect(tx3.soldeEspeceAvant, 110000.0);
      expect(tx3.soldeEspeceApres, 110000.0);

      // Tx4 (Retrait 30 000) : Avant = 110 000 F, Après = 80 000 F
      expect(tx4.soldeEspeceAvant, 110000.0);
      expect(tx4.soldeEspeceApres, 80000.0);

      // Solde final caisse
      expect(ctrl.soldeEspece, 80000.0);
    });

    test('TransactionModel utilise soldeEspeceRaw si renseigné dans le JSON',
        () {
      final json = {
        'id': 'tx_json',
        'user_id': 'u1',
        'type': 'depot',
        'category': 'UV',
        'client_name': 'Test',
        'client_phone': '70000000',
        'amount': 5000,
        'commission': 7,
        'balance_after': 95000,
        'solde_espece_avant': 45000,
        'solde_espece_apres': 50000,
        'created_at': DateTime.now().toIso8601String(),
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.soldeEspeceAvant, 45000.0);
      expect(tx.soldeEspeceApres, 50000.0);
    });
  });
}
