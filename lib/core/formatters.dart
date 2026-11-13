import 'package:intl/intl.dart';

/// Formatting helpers. Western digits are used in both languages, which is
/// what Pakistani electricity bills print.
class Fmt {
  const Fmt._();

  static final NumberFormat _money = NumberFormat('#,##0', 'en');
  static final NumberFormat _money2 = NumberFormat('#,##0.00', 'en');
  static final NumberFormat _units = NumberFormat('#,##0.##', 'en');

  /// Whole rupees, e.g. "PKR 12,345".
  static String pkr(double amount) => 'PKR ${_money.format(amount.round())}';

  /// Two decimals, e.g. "PKR 1,234.56".
  static String pkr2(double amount) => 'PKR ${_money2.format(amount)}';

  static String rate(double rate) => _money2.format(rate);

  static String units(double units) => _units.format(units);

  static String date(DateTime date, String languageCode) =>
      DateFormat('d MMM yyyy, h:mm a', languageCode == 'ur' ? 'ur' : 'en').format(date);

  /// "0–100", "101–200", "700+".
  static String slabRange(int fromExclusive, int? toInclusive) {
    if (toInclusive == null) return '${_units.format(fromExclusive)}+';
    final start = fromExclusive == 0 ? 0 : fromExclusive + 1;
    return '${_units.format(start)}–${_units.format(toInclusive)}';
  }
}
