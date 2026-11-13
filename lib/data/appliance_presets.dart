import '../models/appliance.dart';

/// Typical wattage and usage for common Pakistani household appliances.
/// Users can adjust every value after picking a preset.
const List<AppliancePreset> appliancePresets = [
  AppliancePreset(nameKey: 'presetFan', watts: 75, hoursPerDay: 12, daysPerMonth: 30),
  AppliancePreset(nameKey: 'presetLed', watts: 12, hoursPerDay: 8, daysPerMonth: 30),
  // Compressor cycles on/off, so effective running hours are well below 24.
  AppliancePreset(nameKey: 'presetFridge', watts: 200, hoursPerDay: 10, daysPerMonth: 30),
  AppliancePreset(nameKey: 'presetTv', watts: 100, hoursPerDay: 6, daysPerMonth: 30),
  AppliancePreset(nameKey: 'presetIron', watts: 1000, hoursPerDay: 0.5, daysPerMonth: 20),
  AppliancePreset(nameKey: 'presetWasher', watts: 500, hoursPerDay: 1, daysPerMonth: 12),
  AppliancePreset(nameKey: 'presetAc', watts: 1800, hoursPerDay: 8, daysPerMonth: 30),
  AppliancePreset(nameKey: 'presetPump', watts: 750, hoursPerDay: 1, daysPerMonth: 30),
];
