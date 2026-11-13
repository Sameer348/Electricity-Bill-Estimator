import 'connection_type.dart';
import 'tariff_config.dart';

/// Units billed inside one slab.
class SlabCharge {
  const SlabCharge({
    required this.fromUnits,
    required this.toUnits,
    required this.units,
    required this.ratePerUnit,
    required this.amount,
  });

  /// Lower bound of the slab (exclusive, i.e. 100 for "101–200").
  final int fromUnits;

  /// Upper bound of the slab (inclusive), `null` for the open-ended slab.
  final int? toUnits;
  final double units;
  final double ratePerUnit;
  final double amount;

  Map<String, dynamic> toJson() => {
        'from': fromUnits,
        'to': toUnits,
        'units': units,
        'rate': ratePerUnit,
        'amount': amount,
      };

  factory SlabCharge.fromJson(Map<String, dynamic> json) => SlabCharge(
        fromUnits: (json['from'] as num).toInt(),
        toUnits: (json['to'] as num?)?.toInt(),
        units: (json['units'] as num).toDouble(),
        ratePerUnit: (json['rate'] as num).toDouble(),
        amount: (json['amount'] as num).toDouble(),
      );
}

/// A computed tax or additional charge line.
class ChargeLine {
  const ChargeLine({required this.name, required this.amount});

  final String name;
  final double amount;

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory ChargeLine.fromJson(Map<String, dynamic> json) => ChargeLine(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

/// Structured output of [BillCalculator.calculateBill].
class BillResult {
  const BillResult({
    required this.units,
    required this.connectionType,
    required this.slabMode,
    required this.slabCharges,
    required this.energyCharges,
    required this.fixedCharges,
    required this.additionalCharges,
    required this.taxes,
  });

  final double units;
  final ConnectionType connectionType;
  final SlabMode slabMode;
  final List<SlabCharge> slabCharges;
  final double energyCharges;
  final double fixedCharges;
  final List<ChargeLine> additionalCharges;
  final List<ChargeLine> taxes;

  double get totalAdditionalCharges =>
      additionalCharges.fold(0, (sum, line) => sum + line.amount);
  double get totalTaxes => taxes.fold(0, (sum, line) => sum + line.amount);
  double get subtotalBeforeTax => energyCharges + fixedCharges + totalAdditionalCharges;
  double get total => subtotalBeforeTax + totalTaxes;
  double get averageCostPerUnit => units > 0 ? total / units : 0;

  Map<String, dynamic> toJson() => {
        'units': units,
        'connectionType': connectionType.name,
        'slabMode': slabMode.name,
        'slabCharges': slabCharges.map((s) => s.toJson()).toList(),
        'energy': energyCharges,
        'fixed': fixedCharges,
        'additional': additionalCharges.map((c) => c.toJson()).toList(),
        'taxes': taxes.map((c) => c.toJson()).toList(),
      };

  factory BillResult.fromJson(Map<String, dynamic> json) {
    List<ChargeLine> lines(String key) => (json[key] as List<dynamic>? ?? const [])
        .map((e) => ChargeLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return BillResult(
      units: (json['units'] as num).toDouble(),
      connectionType: ConnectionType.fromName(json['connectionType'] as String?),
      slabMode: SlabMode.fromName(json['slabMode'] as String?),
      slabCharges: (json['slabCharges'] as List<dynamic>? ?? const [])
          .map((e) => SlabCharge.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      energyCharges: (json['energy'] as num).toDouble(),
      fixedCharges: (json['fixed'] as num? ?? 0).toDouble(),
      additionalCharges: lines('additional'),
      taxes: lines('taxes'),
    );
  }
}
