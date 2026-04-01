enum TransactionType { depot, retrait, nafama, achat, forfait, sewa }
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
  final double commission; // NOUVEAU : Commission automatisée
  final double soldeApres;
  final String? note;
  final DateTime createdAt;

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
  });

  // Logique métier v1.1 : Calcul automatique de la commission
  static double calculateCommission(TransactionType type, double amount) {
    switch (type) {
      case TransactionType.depot: return amount * 0.0014; // 0.14%
      case TransactionType.retrait: return amount * 0.0028; // 0.28%
      case TransactionType.nafama: return amount * 0.0455; // 4.55%
      case TransactionType.achat:
      case TransactionType.forfait:
      case TransactionType.sewa: return amount * 0.10; // 10%
      default: return 0;
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      type: TransactionType.values.byName(json['type']),
      category: TransactionCategory.values.byName(json['category']),
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      merchantPhone: json['merchant_phone']?.toString(),
      amount: asDouble(json['amount']),
      commission: asDouble(json['commission']),
      // Compatibilite ancien schema (solde_apres) / nouveau schema (balance_after)
      soldeApres: asDouble(json['solde_apres'] ?? json['balance_after']),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type.name,
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
