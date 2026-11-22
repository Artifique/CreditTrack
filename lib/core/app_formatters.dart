import 'package:intl/intl.dart';

/// Centralisation des formatages monétaires, numériques, dates et téléphones
/// pour éliminer les instanciations répétitives et unifier les règles d'affichage.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFmt = NumberFormat('#,##0', 'fr_FR');
  static final DateFormat _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateOnlyFmt = DateFormat('dd/MM/yyyy');

  /// Formate un montant numérique (ex: "12 500")
  static String formatAmount(num amount) => _currencyFmt.format(amount);

  /// Formate un montant avec suffixe CFA (ex: "12 500 CFA")
  static String formatMoney(num amount) =>
      '${_currencyFmt.format(amount.round())} CFA';

  /// Formate un montant avec suffixe F (ex: "12 500 F")
  static String formatMoneyShort(num amount) =>
      '${_currencyFmt.format(amount.round())} F';

  /// Formate en notation compacte (ex: "1,5 k")
  static String formatCompact(num amount) =>
      NumberFormat.compact(locale: 'fr_FR').format(amount);

  /// Formate une date et heure : "22/11/2026 18:30"
  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFmt.format(dateTime);

  /// Formate une date seule : "22/11/2026"
  static String formatDate(DateTime dateTime) => _dateOnlyFmt.format(dateTime);

  /// Formate un numéro de téléphone lisiblement (espaces tous les 2-3 chiffres)
  static String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    } else if (digits.length == 8) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)}';
    }
    return phone;
  }
}
