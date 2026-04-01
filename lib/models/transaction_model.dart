import 'package:uuid/uuid.dart';

enum TransactionType { depot, retrait, nafama, achat, forfait, sewa }
enum TransactionCategory { UV, CREDIT }

class TransactionModel {
  final String? id;
  final String userId;
  final TransactionType type;
  final TransactionCategory category;
  final String clientName;
  final String clientPhone;
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
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      type: TransactionType.values.byName(json['type']),
      category: TransactionCategory.values.byName(json['category']),
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      amount: json['amount'].toDouble(),
      commission: json['commission']?.toDouble() ?? 0.0,
      soldeApres: json['solde_apres'].toDouble(),
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
      'amount': amount,
      'commission': commission,
      'solde_apres': soldeApres,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
