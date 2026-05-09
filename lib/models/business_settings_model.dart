import 'commission_rates_model.dart';

class BusinessSettingsModel {
  final bool darkMode;
  final String language;
  final bool autoPrintReceipt;
  final CommissionRates commissionRates;

  const BusinessSettingsModel({
    required this.darkMode,
    required this.language,
    required this.autoPrintReceipt,
    required this.commissionRates,
  });

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) {
    return BusinessSettingsModel(
      darkMode: json['dark_mode'] == true,
      language: (json['language'] ?? 'fr').toString(),
      autoPrintReceipt: json['auto_print_receipt'] == true,
      commissionRates: CommissionRates.fromJson(json['commission_rates']),
    );
  }

  static const empty = BusinessSettingsModel(
    darkMode: false,
    language: 'fr',
    autoPrintReceipt: false,
    commissionRates: CommissionRates.defaults,
  );
}
