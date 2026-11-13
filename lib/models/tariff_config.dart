import 'connection_type.dart';

/// How slab rates are applied to the consumed units.
enum SlabMode {
  /// Each slab's rate applies only to the units that fall inside that slab
  /// (e.g. first 100 units at slab-1 rate, next 100 at slab-2 rate, ...).
  progressive,

  /// All units are charged at the rate of the slab the total falls into.
  /// Some Pakistani categories (e.g. non-protected residential) work this way.
  singleSlab;

  static SlabMode fromName(String? value) => SlabMode.values
      .firstWhere((mode) => mode.name == value, orElse: () => progressive);
}

/// What a [ChargeItem] value is calculated against.
enum ChargeBasis {
  /// A flat PKR amount per bill.
  fixedAmount,

  /// PKR multiplied by consumed units.
  perUnit,

  /// Percentage of energy charges.
  percentOfEnergy,

  /// Percentage of the pre-tax subtotal (energy + fixed + additional charges).
  percentOfSubtotal;

  static ChargeBasis fromName(String? value) => ChargeBasis.values
      .firstWhere((basis) => basis.name == value, orElse: () => fixedAmount);
}

/// One consumption slab. The lower bound is implied by the previous slab's
/// [upToUnits]; a `null` [upToUnits] means "and above".
class TariffSlab {
  const TariffSlab({required this.upToUnits, required this.ratePerUnit});

  final int? upToUnits;
  final double ratePerUnit;

  TariffSlab copyWith({int? upToUnits, bool clearUpper = false, double? ratePerUnit}) {
    return TariffSlab(
      upToUnits: clearUpper ? null : (upToUnits ?? this.upToUnits),
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
    );
  }

  Map<String, dynamic> toJson() => {'upTo': upToUnits, 'rate': ratePerUnit};

  factory TariffSlab.fromJson(Map<String, dynamic> json) => TariffSlab(
        upToUnits: (json['upTo'] as num?)?.toInt(),
        ratePerUnit: (json['rate'] as num).toDouble(),
      );
}

/// A tax, surcharge or other adjustment added on top of energy charges.
class ChargeItem {
  const ChargeItem({
    required this.name,
    required this.basis,
    required this.value,
    required this.isTax,
  });

  final String name;
  final ChargeBasis basis;
  final double value;

  /// Taxes are computed after all non-tax charges and listed separately.
  final bool isTax;

  ChargeItem copyWith({String? name, ChargeBasis? basis, double? value, bool? isTax}) {
    return ChargeItem(
      name: name ?? this.name,
      basis: basis ?? this.basis,
      value: value ?? this.value,
      isTax: isTax ?? this.isTax,
    );
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'basis': basis.name, 'value': value, 'isTax': isTax};

  factory ChargeItem.fromJson(Map<String, dynamic> json) => ChargeItem(
        name: json['name'] as String? ?? '',
        basis: ChargeBasis.fromName(json['basis'] as String?),
        value: (json['value'] as num? ?? 0).toDouble(),
        isTax: json['isTax'] as bool? ?? false,
      );
}

/// Complete, editable tariff definition for one connection type.
///
/// All rates live here (and in persisted user overrides) so the calculation
/// engine never contains hard-coded numbers.
class TariffConfig {
  const TariffConfig({
    required this.connectionType,
    required this.slabs,
    required this.slabMode,
    required this.fixedChargePerMonth,
    required this.charges,
    this.note = '',
  });

  final ConnectionType connectionType;
  final List<TariffSlab> slabs;
  final SlabMode slabMode;
  final double fixedChargePerMonth;
  final List<ChargeItem> charges;

  /// Free-text note, e.g. the notification the rates were taken from.
  final String note;

  List<ChargeItem> get additionalCharges => charges.where((c) => !c.isTax).toList();
  List<ChargeItem> get taxes => charges.where((c) => c.isTax).toList();

  /// Returns a human-readable error key if the slabs are inconsistent, or
  /// `null` when the configuration can be used for calculations.
  String? validate() {
    if (slabs.isEmpty) return 'errNoSlabs';
    int previousUpper = 0;
    for (var i = 0; i < slabs.length; i++) {
      final slab = slabs[i];
      if (slab.ratePerUnit < 0 || !slab.ratePerUnit.isFinite) return 'errRate';
      final isLast = i == slabs.length - 1;
      if (isLast) {
        if (slab.upToUnits != null) return 'errLastSlabOpen';
      } else {
        final upper = slab.upToUnits;
        if (upper == null || upper <= previousUpper) return 'errSlabOrder';
        previousUpper = upper;
      }
    }
    if (fixedChargePerMonth < 0) return 'errRate';
    for (final charge in charges) {
      if (charge.value < 0 || !charge.value.isFinite) return 'errRate';
    }
    return null;
  }

  TariffConfig copyWith({
    List<TariffSlab>? slabs,
    SlabMode? slabMode,
    double? fixedChargePerMonth,
    List<ChargeItem>? charges,
    String? note,
  }) {
    return TariffConfig(
      connectionType: connectionType,
      slabs: slabs ?? this.slabs,
      slabMode: slabMode ?? this.slabMode,
      fixedChargePerMonth: fixedChargePerMonth ?? this.fixedChargePerMonth,
      charges: charges ?? this.charges,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'connectionType': connectionType.name,
        'slabs': slabs.map((s) => s.toJson()).toList(),
        'slabMode': slabMode.name,
        'fixedCharge': fixedChargePerMonth,
        'charges': charges.map((c) => c.toJson()).toList(),
        'note': note,
      };

  factory TariffConfig.fromJson(Map<String, dynamic> json) => TariffConfig(
        connectionType: ConnectionType.fromName(json['connectionType'] as String?),
        slabs: (json['slabs'] as List<dynamic>)
            .map((e) => TariffSlab.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        slabMode: SlabMode.fromName(json['slabMode'] as String?),
        fixedChargePerMonth: (json['fixedCharge'] as num? ?? 0).toDouble(),
        charges: (json['charges'] as List<dynamic>? ?? const [])
            .map((e) => ChargeItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        note: json['note'] as String? ?? '',
      );
}
