enum TransactionType {
  depot,
  retrait,
  nafama,
  transfertUv,
  transfertC2c,
  transfertProfitUv,
  achat,
  forfait,
  sewa,
}

enum TransactionCategory { UV, CREDIT }

class TransactionModel {
  final String? id;
  final String userId;
  final TransactionType type;
  final TransactionCategory category;
  final String clientName;
  final String clientPhone;
  /// Numéro d'opération de l'agent (parmi ceux enregistrés sur le profil).
  final String? merchantPhone;
  final double amount;
  final double commission;
  final double soldeApres;
  final String? note;
  final DateTime createdAt;
  /// Numéro de journal lisible (reçu / audit), assigné côté serveur.
  final int? journalSeq;

  TransactionModel({
    this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.clientName,
    required this.clientPhone,
    this.merchantPhone,
    required this.amount,
    required this.commission,
    required this.soldeApres,
    this.note,
    required this.createdAt,
    this.journalSeq,
  });

  static double calculateCommission(TransactionType type, double amount) {
    switch (type) {
      case TransactionType.depot:
        return amount * 0.0014;
      case TransactionType.retrait:
        return amount * 0.0028;
      case TransactionType.nafama:
        return amount * 0.0455;
      case TransactionType.transfertUv:
      case TransactionType.transfertC2c:
      case TransactionType.achat:
      case TransactionType.transfertProfitUv:
        return 0;
      case TransactionType.forfait:
      case TransactionType.sewa:
        return amount * 0.10;
    }
  }

  static String typeToApi(TransactionType type) {
    switch (type) {
      case TransactionType.transfertUv:
        return 'transfert_uv';
      case TransactionType.transfertC2c:
        return 'transfert_c2c';
      case TransactionType.transfertProfitUv:
        return 'transfert_profit_uv';
      default:
        return type.name;
    }
  }

  static TransactionType typeFromApi(String raw) {
    switch (raw) {
      case 'transfert_uv':
        return TransactionType.transfertUv;
      case 'transfert_c2c':
        return TransactionType.transfertC2c;
      case 'transfert_profit_uv':
        return TransactionType.transfertProfitUv;
      default:
        return TransactionType.values.byName(raw);
    }
  }

  static String typeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.depot:
        return 'Dépôt';
      case TransactionType.retrait:
        return 'Retrait';
      case TransactionType.nafama:
        return 'Nafama';
      case TransactionType.transfertUv:
        return 'Transfert UV';
      case TransactionType.transfertC2c:
        return 'Transfert C2C';
      case TransactionType.transfertProfitUv:
        return 'Transfert profit UV';
      case TransactionType.achat:
        return 'Achat crédit';
      case TransactionType.forfait:
        return 'Forfait';
      case TransactionType.sewa:
        return 'Sewa';
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    int? asInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final rawType = json['type']?.toString() ?? 'depot';

    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      type: TransactionModel.typeFromApi(rawType),
      category: TransactionCategory.values.byName(json['category']),
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      merchantPhone: json['merchant_phone']?.toString(),
      amount: asDouble(json['amount']),
      commission: asDouble(json['commission']),
      soldeApres: asDouble(json['solde_apres'] ?? json['balance_after']),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      journalSeq: asInt(json['journal_seq']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': TransactionModel.typeToApi(type),
      'category': category.name,
      'client_name': clientName,
      'client_phone': clientPhone,
      if (merchantPhone != null && merchantPhone!.trim().isNotEmpty) 'merchant_phone': merchantPhone!.trim(),
      'amount': amount,
      'commission': commission,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
