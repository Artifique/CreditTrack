class ProfileModel {
  final String id;
  final String businessName;
  final String? ownerName;
  final String? phoneNumber;
  final double soldeUv;
  final double soldeCredit;
  final String currency;

  ProfileModel({
    required this.id,
    required this.businessName,
    this.ownerName,
    this.phoneNumber,
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

    return ProfileModel(
      id: json['id'] as String,
      businessName: (json['business_name'] ?? 'Mon Commerce').toString(),
      ownerName: json['owner_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      soldeUv: asDouble(json['solde_uv']),
      soldeCredit: asDouble(json['solde_credit']),
      currency: (json['currency'] ?? 'CFA').toString(),
    );
  }
}
