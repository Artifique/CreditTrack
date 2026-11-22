class SimCardModel {
  final String phone;
  final String name;
  final double soldeUv;
  final double soldeCredit;

  const SimCardModel({
    required this.phone,
    required this.name,
    this.soldeUv = 0.0,
    this.soldeCredit = 0.0,
  });

  String get displayName => name.trim().isNotEmpty ? name.trim() : "SIM $phone";

  /// Montant total restant sur la carte SIM (UV + Crédit)
  double get totalBalance => soldeUv + soldeCredit;

  /// Indique si la SIM contient encore des fonds (bloquant la suppression)
  bool get hasMoney => totalBalance > 0;

  SimCardModel copyWith({
    String? phone,
    String? name,
    double? soldeUv,
    double? soldeCredit,
  }) {
    return SimCardModel(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      soldeUv: soldeUv ?? this.soldeUv,
      soldeCredit: soldeCredit ?? this.soldeCredit,
    );
  }
}
