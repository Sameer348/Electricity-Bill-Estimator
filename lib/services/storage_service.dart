import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/connection_type.dart';
import '../models/saved_estimate.dart';
import '../models/tariff_config.dart';

/// Persistence contract, so the controller can be tested with a fake.
abstract class StorageService {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);

  Future<List<SavedEstimate>> loadHistory();
  Future<void> saveHistory(List<SavedEstimate> history);

  /// User-edited tariffs; missing entries fall back to built-in defaults.
  Future<Map<ConnectionType, TariffConfig>> loadTariffOverrides();
  Future<void> saveTariffOverrides(Map<ConnectionType, TariffConfig> tariffs);
}

/// Local, on-device storage using SharedPreferences (JSON strings).
/// No data ever leaves the device.
class PrefsStorageService implements StorageService {
  PrefsStorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'settings_v1';
  static const _historyKey = 'history_v1';
  static const _tariffsKey = 'tariffs_v1';

  static Future<PrefsStorageService> create() async =>
      PrefsStorageService(await SharedPreferences.getInstance());

  @override
  Future<AppSettings> loadSettings() async {
    final json = _decodeMap(_prefs.getString(_settingsKey));
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

  @override
  Future<List<SavedEstimate>> loadHistory() async {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final estimates = <SavedEstimate>[];
      for (final item in list) {
        try {
          estimates.add(SavedEstimate.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (e) {
          debugPrint('Skipping unreadable history entry: $e');
        }
      }
      return estimates;
    } catch (e) {
      debugPrint('History could not be read: $e');
      return [];
    }
  }

  @override
  Future<void> saveHistory(List<SavedEstimate> history) => _prefs.setString(
        _historyKey,
        jsonEncode(history.map((e) => e.toJson()).toList()),
      );

  @override
  Future<Map<ConnectionType, TariffConfig>> loadTariffOverrides() async {
    final json = _decodeMap(_prefs.getString(_tariffsKey));
    if (json == null) return {};
    final result = <ConnectionType, TariffConfig>{};
    for (final entry in json.entries) {
      try {
        final config = TariffConfig.fromJson(Map<String, dynamic>.from(entry.value as Map));
        if (config.validate() == null) result[config.connectionType] = config;
      } catch (e) {
        debugPrint('Ignoring invalid saved tariff ${entry.key}: $e');
      }
    }
    return result;
  }

  @override
  Future<void> saveTariffOverrides(Map<ConnectionType, TariffConfig> tariffs) =>
      _prefs.setString(
        _tariffsKey,
        jsonEncode({for (final e in tariffs.entries) e.key.name: e.value.toJson()}),
      );

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      debugPrint('Stored JSON could not be read: $e');
      return null;
    }
  }
}
