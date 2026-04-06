/// Soldes et bénéfices cumulés pour un numéro d'opération (ligne Supabase `operation_phone_wallets`).
class OperationPhoneWalletModel {
  final String phone;
  final double soldeUv;
  final double soldeCredit;
  final double profitUv;
  final double profitCredit;

  const OperationPhoneWalletModel({
    required this.phone,
    required this.soldeUv,
    required this.soldeCredit,
    required this.profitUv,
    required this.profitCredit,
  });

  factory OperationPhoneWalletModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return OperationPhoneWalletModel(
      phone: (json['phone'] ?? '').toString(),
      soldeUv: d(json['solde_uv']),
      soldeCredit: d(json['solde_credit']),
      profitUv: d(json['profit_uv']),
      profitCredit: d(json['profit_credit']),
    );
  }

  static const empty = OperationPhoneWalletModel(
    phone: '',
    soldeUv: 0,
    soldeCredit: 0,
    profitUv: 0,
    profitCredit: 0,
  );
}
