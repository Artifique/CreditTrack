/// Multiplicateurs du montant (ex. 0.0014 = 0,14 %), alignés sur `business_settings.commission_rates` / Postgres.
class CommissionRates {
  final double depot;
  final double retrait;
  final double nafama;
  final double forfait;
  final double sewa;

  const CommissionRates({
    required this.depot,
    required this.retrait,
    required this.nafama,
    required this.forfait,
    required this.sewa,
  });

  static const defaults = CommissionRates(
    depot: 0.0014,
    retrait: 0.0028,
    nafama: 0.0455,
    forfait: 0.10,
    sewa: 0.10,
  );

  Map<String, dynamic> toJson() => {
        'depot': depot,
        'retrait': retrait,
        'nafama': nafama,
        'forfait': forfait,
        'sewa': sewa,
      };

  factory CommissionRates.fromJson(dynamic raw) {
    if (raw is! Map) return CommissionRates.defaults;
    final m = Map<String, dynamic>.from(raw);

    double read(String key, double fallback) {
      final v = m[key];
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return CommissionRates(
      depot: read('depot', CommissionRates.defaults.depot),
      retrait: read('retrait', CommissionRates.defaults.retrait),
      nafama: read('nafama', CommissionRates.defaults.nafama),
      forfait: read('forfait', CommissionRates.defaults.forfait),
      sewa: read('sewa', CommissionRates.defaults.sewa),
    );
  }

  /// Valeur affichée en pourcentage (multiplicateur × 100).
  double get percentDepot => depot * 100;
  double get percentRetrait => retrait * 100;
  double get percentNafama => nafama * 100;
  double get percentForfait => forfait * 100;
  double get percentSewa => sewa * 100;

  /// À partir d’un pourcentage saisi (ex. 0.14 ou 10).
  static CommissionRates fromPercentages({
    required double depotPct,
    required double retraitPct,
    required double nafamaPct,
    required double forfaitPct,
    required double sewaPct,
  }) {
    return CommissionRates(
      depot: depotPct / 100,
      retrait: retraitPct / 100,
      nafama: nafamaPct / 100,
      forfait: forfaitPct / 100,
      sewa: sewaPct / 100,
    );
  }
}
