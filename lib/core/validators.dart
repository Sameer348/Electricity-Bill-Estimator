/// Input limits and parsing helpers shared by forms and tests.
class InputLimits {
  const InputLimits._();

  /// Upper bound for a single monthly reading; anything above is almost
  /// certainly a typo for a household/small commercial meter.
  static const double maxUnits = 100000;
  static const double maxWatts = 10000;
  static const double maxHoursPerDay = 24;
  static const int maxDaysPerMonth = 31;
}

/// Parses user-typed numbers, tolerating thousands separators and spaces.
double? parseNumber(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim().replaceAll(',', '').replaceAll(' ', '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

/// Returns a localization key describing what is wrong with [raw] as a
/// units value, or `null` when it is valid.
String? validateUnits(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'errEmptyUnits';
  final value = parseNumber(raw);
  if (value == null) return 'errInvalidNumber';
  if (value < 0) return 'errNegative';
  if (value == 0) return 'errZero';
  if (value > InputLimits.maxUnits) return 'errTooLarge';
  return null;
}
