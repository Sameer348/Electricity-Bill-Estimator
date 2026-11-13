/// An appliance entry in the appliance calculator.
class Appliance {
  const Appliance({
    required this.name,
    required this.watts,
    required this.hoursPerDay,
    required this.daysPerMonth,
  });

  final String name;
  final double watts;
  final double hoursPerDay;
  final int daysPerMonth;

  /// Monthly consumption in kWh (= billing units).
  double get monthlyKwh => watts * hoursPerDay * daysPerMonth / 1000;
}

/// A built-in starting point; values are typical, not measured.
class AppliancePreset {
  const AppliancePreset({
    required this.nameKey,
    required this.watts,
    required this.hoursPerDay,
    required this.daysPerMonth,
  });

  /// Localization key for the preset's display name.
  final String nameKey;
  final double watts;
  final double hoursPerDay;
  final int daysPerMonth;
}
