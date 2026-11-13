import 'dart:math' as math;

import '../models/bill_result.dart';
import '../models/tariff_config.dart';

/// Pure, stateless bill calculation engine.
///
/// It knows nothing about specific rates: everything comes from the
/// [TariffConfig] passed in, so rates can change without touching this code.
class BillCalculator {
  const BillCalculator();

  /// Calculates an estimated bill for [units] kWh.
  ///
  /// Order of operations:
  /// 1. Energy charges from slabs ([SlabMode.progressive] or [SlabMode.singleSlab]).
  /// 2. Fixed monthly charge.
  /// 3. Non-tax additional charges (surcharges, adjustments). For these,
  ///    "% of subtotal" means % of (energy + fixed).
  /// 4. Taxes, where "% of subtotal" means % of (energy + fixed + additional).
  BillResult calculateBill({required double units, required TariffConfig tariff}) {
    if (units.isNaN || units.isInfinite || units < 0) {
      throw ArgumentError.value(units, 'units', 'must be a finite, non-negative number');
    }
    final configError = tariff.validate();
    if (configError != null) {
      throw ArgumentError('Invalid tariff configuration: $configError');
    }

    final slabCharges = tariff.slabMode == SlabMode.progressive
        ? _progressiveSlabs(units, tariff.slabs)
        : _singleSlab(units, tariff.slabs);
    final energy = _round(slabCharges.fold<double>(0, (sum, s) => sum + s.amount));
    final fixed = _round(tariff.fixedChargePerMonth);

    final additional = [
      for (final charge in tariff.additionalCharges)
        ChargeLine(
          name: charge.name,
          amount: _chargeAmount(charge, units: units, energy: energy, subtotal: energy + fixed),
        ),
    ];
    final additionalTotal = additional.fold<double>(0, (sum, c) => sum + c.amount);
    final taxableSubtotal = energy + fixed + additionalTotal;

    final taxes = [
      for (final charge in tariff.taxes)
        ChargeLine(
          name: charge.name,
          amount: _chargeAmount(charge, units: units, energy: energy, subtotal: taxableSubtotal),
        ),
    ];

    return BillResult(
      units: units,
      connectionType: tariff.connectionType,
      slabMode: tariff.slabMode,
      slabCharges: slabCharges,
      energyCharges: energy,
      fixedCharges: fixed,
      additionalCharges: additional,
      taxes: taxes,
    );
  }

  List<SlabCharge> _progressiveSlabs(double units, List<TariffSlab> slabs) {
    final charges = <SlabCharge>[];
    var lower = 0;
    for (final slab in slabs) {
      if (units <= lower) break;
      final upper = slab.upToUnits;
      final unitsInSlab = (upper == null ? units : math.min(units, upper.toDouble())) - lower;
      charges.add(SlabCharge(
        fromUnits: lower,
        toUnits: upper,
        units: unitsInSlab,
        ratePerUnit: slab.ratePerUnit,
        amount: _round(unitsInSlab * slab.ratePerUnit),
      ));
      if (upper == null) break;
      lower = upper;
    }
    return charges;
  }

  List<SlabCharge> _singleSlab(double units, List<TariffSlab> slabs) {
    if (units <= 0) return const [];
    var lower = 0;
    for (final slab in slabs) {
      final upper = slab.upToUnits;
      if (upper == null || units <= upper) {
        return [
          SlabCharge(
            fromUnits: lower,
            toUnits: upper,
            units: units,
            ratePerUnit: slab.ratePerUnit,
            amount: _round(units * slab.ratePerUnit),
          ),
        ];
      }
      lower = upper;
    }
    return const [];
  }

  double _chargeAmount(
    ChargeItem charge, {
    required double units,
    required double energy,
    required double subtotal,
  }) {
    final amount = switch (charge.basis) {
      ChargeBasis.fixedAmount => charge.value,
      ChargeBasis.perUnit => charge.value * units,
      ChargeBasis.percentOfEnergy => energy * charge.value / 100,
      ChargeBasis.percentOfSubtotal => subtotal * charge.value / 100,
    };
    return _round(amount);
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}
