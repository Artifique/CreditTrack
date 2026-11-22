import 'package:credit_trak/controllers/theme_mode_controller.dart';
import 'package:credit_trak/core/app_color_palette.dart';
import 'package:credit_trak/core/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppColorPalette Tests', () {
    test('5 palettes must be registered with unique IDs', () {
      expect(AppColorPalette.palettes.length, 5);
      final ids = AppColorPalette.palettes.map((p) => p.id).toSet();
      expect(ids.length, 5);
      expect(ids.contains(AppPaletteId.orange), isTrue);
      expect(ids.contains(AppPaletteId.ocean), isTrue);
      expect(ids.contains(AppPaletteId.emerald), isTrue);
      expect(ids.contains(AppPaletteId.violet), isTrue);
      expect(ids.contains(AppPaletteId.ruby), isTrue);
    });

    test('Each palette has primary and secondary colors and gradients', () {
      for (final p in AppColorPalette.palettes) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.primary500, isNotNull);
        expect(p.primary600, isNotNull);
        expect(p.secondary500, isNotNull);
        expect(p.primaryGradient.colors.length, 2);
        expect(p.secondaryGradient.colors.length, 2);
        expect(p.cardGradientUV.colors.length, greaterThanOrEqualTo(2));
        expect(p.cardGradientCredit.colors.length, greaterThanOrEqualTo(2));
        expect(p.cardGradientCash.colors.length, greaterThanOrEqualTo(2));
        expect(p.cardGradientProfitUV.colors.length, greaterThanOrEqualTo(2));
        expect(
            p.cardGradientProfitCredit.colors.length, greaterThanOrEqualTo(2));
      }
    });

    test('AppColorPalette.fromString handles valid and invalid keys', () {
      expect(AppColorPalette.fromString('ocean').id, AppPaletteId.ocean);
      expect(AppColorPalette.fromString('EMERALD').id, AppPaletteId.emerald);
      expect(AppColorPalette.fromString('violet').id, AppPaletteId.violet);
      expect(AppColorPalette.fromString('ruby').id, AppPaletteId.ruby);
      expect(AppColorPalette.fromString('orange').id, AppPaletteId.orange);
      expect(AppColorPalette.fromString('unknown_key').id, AppPaletteId.orange);
      expect(AppColorPalette.fromString(null).id, AppPaletteId.orange);
    });

    test('ThemeModeController updates active palette and AppTokens', () async {
      final controller = ThemeModeController.instance;
      await controller.init();

      await controller.setPalette(AppPaletteId.ocean);
      expect(controller.paletteId, AppPaletteId.ocean);
      expect(AppTokens.currentPalette.id, AppPaletteId.ocean);
      expect(AppTokens.primary500, AppColorPalette.ocean.primary500);

      await controller.setPalette(AppPaletteId.violet);
      expect(controller.paletteId, AppPaletteId.violet);
      expect(AppTokens.currentPalette.id, AppPaletteId.violet);
      expect(AppTokens.primary500, AppColorPalette.violet.primary500);
    });
  });
}
