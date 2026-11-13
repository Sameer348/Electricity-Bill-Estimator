/// Consumer category used to pick a tariff configuration.
enum ConnectionType {
  residential,
  commercial;

  /// Localization key for the display name.
  String get labelKey => name;

  static ConnectionType fromName(String? value) => ConnectionType.values
      .firstWhere((type) => type.name == value, orElse: () => residential);
}
