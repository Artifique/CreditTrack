import 'package:flutter_test/flutter_test.dart';
import 'package:credit_trak/core/app_formatters.dart';

void main() {
  group('AppFormatters Tests', () {
    test('formatAmount formats numbers correctly', () {
      expect(
          AppFormatters.formatAmount(1000)
              .replaceAll('\u202f', ' ')
              .replaceAll('\u00a0', ' '),
          '1 000');
      expect(
          AppFormatters.formatAmount(50000)
              .replaceAll('\u202f', ' ')
              .replaceAll('\u00a0', ' '),
          '50 000');
    });

    test('formatMoney formats amounts with currency symbol', () {
      expect(
          AppFormatters.formatMoney(2500).contains('2 500') ||
              AppFormatters.formatMoney(2500).contains('2\u202f500'),
          isTrue);
      expect(AppFormatters.formatMoney(2500).endsWith('CFA'), isTrue);
    });

    test('formatPhone formats 8 and 9 digits correctly', () {
      expect(AppFormatters.formatPhone('70123456'), '70 12 34 56');
      expect(AppFormatters.formatPhone('771234567'), '77 123 45 67');
      expect(AppFormatters.formatPhone('123'), '123');
    });
  });
}
