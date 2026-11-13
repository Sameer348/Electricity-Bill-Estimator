import 'package:flutter/material.dart';

import '../data/default_tariffs.dart';
import '../models/app_settings.dart';
import '../models/bill_result.dart';
import '../models/connection_type.dart';
import '../models/saved_estimate.dart';
import '../models/tariff_config.dart';
import '../services/bill_calculator.dart';
import '../services/storage_service.dart';

/// Single source of app state: settings, tariffs and history.
class AppController extends ChangeNotifier {
  AppController({required this._storage, this._calculator = const BillCalculator()});

  final StorageService _storage;
  final BillCalculator _calculator;

  /// Max history entries kept on device.
  static const int historyLimit = 200;

  AppSettings _settings = const AppSettings();
  List<SavedEstimate> _history = [];
  Map<ConnectionType, TariffConfig> _tariffOverrides = {};

  AppSettings get settings => _settings;
  List<SavedEstimate> get history => List.unmodifiable(_history);
  Locale get locale => Locale(_settings.languageCode);

  Future<void> load() async {
    _settings = await _storage.loadSettings();
    _history = await _storage.loadHistory();
    _tariffOverrides = await _storage.loadTariffOverrides();
    notifyListeners();
  }

  // ---- Tariffs ----

  TariffConfig tariffFor(ConnectionType type) =>
      _tariffOverrides[type] ?? DefaultTariffs.forType(type);

  bool isCustomTariff(ConnectionType type) => _tariffOverrides.containsKey(type);

  Future<void> updateTariff(TariffConfig config) async {
    final error = config.validate();
    if (error != null) throw ArgumentError(error);
    _tariffOverrides = {..._tariffOverrides, config.connectionType: config};
    notifyListeners();
    await _storage.saveTariffOverrides(_tariffOverrides);
  }

  Future<void> resetTariff(ConnectionType type) async {
    _tariffOverrides = {..._tariffOverrides}..remove(type);
    notifyListeners();
    await _storage.saveTariffOverrides(_tariffOverrides);
  }

  BillResult calculate(double units, ConnectionType type) =>
      _calculator.calculateBill(units: units, tariff: tariffFor(type));

  // ---- Settings ----

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _storage.saveSettings(settings);
  }

  // ---- History ----

  Future<SavedEstimate> saveEstimate(BillResult result) async {
    final now = DateTime.now();
    final estimate = SavedEstimate(
      id: now.microsecondsSinceEpoch.toString(),
      savedAt: now,
      result: result,
    );
    _history = [estimate, ..._history].take(historyLimit).toList();
    notifyListeners();
    await _storage.saveHistory(_history);
    return estimate;
  }

  Future<void> deleteEstimate(String id) async {
    _history = _history.where((e) => e.id != id).toList();
    notifyListeners();
    await _storage.saveHistory(_history);
  }

  /// Re-inserts an estimate (used by "Undo" after deleting).
  Future<void> restoreEstimate(SavedEstimate estimate) async {
    _history = [..._history, estimate]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    notifyListeners();
    await _storage.saveHistory(_history);
  }

  Future<void> clearHistory() async {
    _history = [];
    notifyListeners();
    await _storage.saveHistory(_history);
  }
}
