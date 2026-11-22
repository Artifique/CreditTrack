import 'package:credit_trak/models/sim_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Protection Suppression SIM - Tests Règle de Sécurité', () {
    test(
        'SIM avec solde UV > 0 est détectée comme ayant de l argent (hasMoney = true)',
        () {
      const sim = SimCardModel(
        phone: '77123456',
        name: 'Orange Money 01',
        soldeUv: 50000,
        soldeCredit: 0,
      );

      expect(sim.totalBalance, 50000.0);
      expect(sim.hasMoney, isTrue);
    });

    test(
        'SIM avec solde Crédit > 0 est détectée comme ayant de l argent (hasMoney = true)',
        () {
      const sim = SimCardModel(
        phone: '77123457',
        name: 'Orange Recharges',
        soldeUv: 0,
        soldeCredit: 12500,
      );

      expect(sim.totalBalance, 12500.0);
      expect(sim.hasMoney, isTrue);
    });

    test(
        'SIM avec soldes UV et Crédit > 0 cumule correctement les fonds restants',
        () {
      const sim = SimCardModel(
        phone: '77123458',
        name: 'SIM Principale',
        soldeUv: 30000,
        soldeCredit: 5000,
      );

      expect(sim.totalBalance, 35000.0);
      expect(sim.hasMoney, isTrue);
    });

    test('SIM sans argent (0 CFA) autorise la suppression (hasMoney = false)',
        () {
      const sim = SimCardModel(
        phone: '77123459',
        name: 'SIM Vide',
        soldeUv: 0,
        soldeCredit: 0,
      );

      expect(sim.totalBalance, 0.0);
      expect(sim.hasMoney, isFalse);
    });
  });
}
