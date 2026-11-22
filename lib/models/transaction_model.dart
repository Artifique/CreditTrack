import 'package:flutter/material.dart';

import '../controllers/cash_balance_controller.dart';
import 'commission_rates_model.dart';

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
  transfertCredit,
}

// ignore: constant_identifier_names
enum TransactionCategory { UV, CREDIT }

class TransactionModel {
  final String? id;
  final String userId;
  final TransactionType type;
  final TransactionCategory category;
  final String clientName;
  final String clientPhone;

  /// Numéro de transfert de l'agent (parmi ceux enregistrés sur le profil).
  final String? merchantPhone;
  final double amount;
  final double commission;
  final double soldeApres;
  final double? soldeAvantRaw;

  /// Solde Espèce universel (caisse physique) après l'opération (si persisté)
  final double? soldeEspeceApresRaw;

  /// Solde Espèce universel (caisse physique) avant l'opération (si persisté)
  final double? soldeEspeceAvantRaw;

  final String? note;
  final DateTime createdAt;

  /// Numéro de journal lisible (reçu / audit), assigné côté serveur.
  final int? journalSeq;

  /// Solde du compte avant l'opération (issu de la base ou calculé par le sens du flux)
  double get soldeAvant {
    if (soldeAvantRaw != null && soldeAvantRaw! > 0) return soldeAvantRaw!;
    switch (type) {
      case TransactionType.depot:
      case TransactionType.nafama:
      case TransactionType.transfertC2c:
      case TransactionType.forfait:
      case TransactionType.sewa:
      case TransactionType.transfertCredit:
        return soldeApres + amount;
      case TransactionType.retrait:
      case TransactionType.transfertUv:
      case TransactionType.transfertProfitUv:
      case TransactionType.achat:
        return (soldeApres - amount) > 0 ? (soldeApres - amount) : 0;
    }
  }

  /// Solde Espèce (caisse physique) avant cette opération
  double get soldeEspeceAvant {
    if (soldeEspeceAvantRaw != null) return soldeEspeceAvantRaw!;
    return CashBalanceController.instance.getCashBefore(this);
  }

  /// Solde Espèce (caisse physique) après cette opération
  double get soldeEspeceApres {
    if (soldeEspeceApresRaw != null) return soldeEspeceApresRaw!;
    return CashBalanceController.instance.getCashAfter(this);
  }

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
    this.soldeAvantRaw,
    this.soldeEspeceApresRaw,
    this.soldeEspeceAvantRaw,
    this.note,
    required this.createdAt,
    this.journalSeq,
  });

  static double calculateCommission(
    TransactionType type,
    double amount, {
    CommissionRates rates = CommissionRates.defaults,
  }) {
    switch (type) {
      case TransactionType.depot:
        return amount * rates.depot;
      case TransactionType.retrait:
        return amount * rates.retrait;
      case TransactionType.nafama:
        return amount * rates.nafama;
      case TransactionType.transfertUv:
      case TransactionType.transfertC2c:
      case TransactionType.achat:
      case TransactionType.transfertProfitUv:
        return 0;
      case TransactionType.forfait:
        return amount * rates.forfait;
      case TransactionType.sewa:
        return amount * rates.sewa;
      case TransactionType.transfertCredit:
        return amount * rates.transfertCredit;
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
      case TransactionType.transfertCredit:
        return 'transfert_credit';
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
      case 'transfert_credit':
        return TransactionType.transfertCredit;
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
        return 'Transfert Profit UV';
      case TransactionType.achat:
        return 'Achat crédit';
      case TransactionType.forfait:
        return 'Forfait';
      case TransactionType.sewa:
        return 'Sewa';
      case TransactionType.transfertCredit:
        return 'Transfert de crédit';
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
      soldeAvantRaw:
          json['balance_before'] != null || json['solde_avant'] != null
              ? asDouble(json['balance_before'] ?? json['solde_avant'])
              : null,
      soldeEspeceApresRaw: json['solde_espece_apres'] != null ||
              json['solde_espece_after'] != null
          ? asDouble(json['solde_espece_apres'] ?? json['solde_espece_after'])
          : null,
      soldeEspeceAvantRaw: json['solde_espece_avant'] != null ||
              json['solde_espece_before'] != null
          ? asDouble(json['solde_espece_avant'] ?? json['solde_espece_before'])
          : null,
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
      if (merchantPhone != null && merchantPhone!.trim().isNotEmpty)
        'merchant_phone': merchantPhone!.trim(),
      'amount': amount,
      'commission': commission,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Affichage liste / détail : rouge pour dépôt, vert pour retrait ; sinon couleur neutre.
extension TransactionTypeAmountStyle on TransactionType {
  Color amountDisplayColor(Color neutral) {
    switch (this) {
      case TransactionType.depot:
        return Colors.red;
      case TransactionType.retrait:
        return Colors.green;
      default:
        return neutral;
    }
  }
}
