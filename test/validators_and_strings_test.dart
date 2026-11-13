import 'package:electricity_bill_estimator/core/app_strings.dart';
import 'package:electricity_bill_estimator/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateUnits', () {
    test('accepts normal values', () {
      expect(validateUnits('250'), isNull);
      expect(validateUnits(' 1,250 '), isNull);
      expect(validateUnits('99.5'), isNull);
    });

    test('rejects bad input with specific messages', () {
      expect(validateUnits(null), 'errEmptyUnits');
      expect(validateUnits('   '), 'errEmptyUnits');
      expect(validateUnits('abc'), 'errInvalidNumber');
      expect(validateUnits('1.2.3'), 'errInvalidNumber');
      expect(validateUnits('-5'), 'errNegative');
      expect(validateUnits('0'), 'errZero');
      expect(validateUnits('100001'), 'errTooLarge');
    });
  });

  test('English and Urdu define the same keys', () {
    final en = AppStrings.values['en']!.keys.toSet();
    final ur = AppStrings.values['ur']!.keys.toSet();
    expect(en.difference(ur), isEmpty, reason: 'missing in Urdu');
    expect(ur.difference(en), isEmpty, reason: 'missing in English');
  });

  test('placeholders are substituted', () {
    expect(const AppStrings('en').t('slabLabel', {'n': '3'}), 'Slab 3');
  });
}
