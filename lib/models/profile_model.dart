class ProfileModel {
  final String id;
  final String businessName;
  final String? ownerName;
  final String? phoneNumber;
  /// Jusqu'à 3 numéros utilisés pour les opérations (agent).
  final List<String> operationPhones;
  final double soldeUv;
  final double soldeCredit;
  final String currency;

  ProfileModel({
    required this.id,
    required this.businessName,
    this.ownerName,
    this.phoneNumber,
    this.operationPhones = const [],
    required this.soldeUv,
    required this.soldeCredit,
    required this.currency,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    List<String> parseOperationPhones(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).take(3).toList();
      }
      return [];
    }

    return ProfileModel(
      id: json['id'] as String,
      businessName: (json['business_name'] ?? 'Mon Commerce').toString(),
      ownerName: json['owner_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      operationPhones: parseOperationPhones(json['operation_phones']),
      soldeUv: asDouble(json['solde_uv']),
      soldeCredit: asDouble(json['solde_credit']),
      currency: (json['currency'] ?? 'CFA').toString(),
    );
  }
}
