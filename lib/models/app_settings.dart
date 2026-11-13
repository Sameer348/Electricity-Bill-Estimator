import 'package:flutter/material.dart';

import 'connection_type.dart';

class AppSettings {
  const AppSettings({
    this.languageCode = 'en',
    this.themeMode = ThemeMode.system,
    this.defaultConnectionType = ConnectionType.residential,
  });

  final String languageCode;
  final ThemeMode themeMode;
  final ConnectionType defaultConnectionType;

  /// The app currently supports PKR only; kept here so it is a single source.
  String get currencyCode => 'PKR';

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    ConnectionType? defaultConnectionType,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      defaultConnectionType: defaultConnectionType ?? this.defaultConnectionType,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': languageCode,
        'theme': themeMode.name,
        'defaultConnection': defaultConnectionType.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        languageCode: json['language'] == 'ur' ? 'ur' : 'en',
        themeMode: ThemeMode.values.firstWhere(
          (mode) => mode.name == json['theme'],
          orElse: () => ThemeMode.system,
        ),
        defaultConnectionType: ConnectionType.fromName(json['defaultConnection'] as String?),
      );
}
