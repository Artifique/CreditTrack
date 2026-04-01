class BusinessSettingsModel {
  final bool darkMode;
  final String language;
  final bool autoPrintReceipt;

  const BusinessSettingsModel({
    required this.darkMode,
    required this.language,
    required this.autoPrintReceipt,
  });

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) {
    return BusinessSettingsModel(
      darkMode: json['dark_mode'] == true,
      language: (json['language'] ?? 'fr').toString(),
      autoPrintReceipt: json['auto_print_receipt'] == true,
    );
  }

  static const empty = BusinessSettingsModel(
    darkMode: false,
    language: 'fr',
    autoPrintReceipt: false,
  );
}
