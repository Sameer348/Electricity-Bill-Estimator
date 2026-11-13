import 'package:electricity_bill_estimator/data/default_tariffs.dart';
import 'package:electricity_bill_estimator/models/connection_type.dart';
import 'package:electricity_bill_estimator/models/tariff_config.dart';
import 'package:electricity_bill_estimator/services/bill_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = BillCalculator();

  /// Simple round-number tariff so expected values are easy to verify.
  const simpleTariff = TariffConfig(
    connectionType: ConnectionType.residential,
    slabMode: SlabMode.progressive,
    slabs: [
      TariffSlab(upToUnits: 100, ratePerUnit: 10),
      TariffSlab(upToUnits: 200, ratePerUnit: 20),
      TariffSlab(upToUnits: null, ratePerUnit: 30),
    ],
    fixedChargePerMonth: 0,
    charges: [],
  );

  group('progressive slabs', () {
    test('units within the first slab use only the first rate', () {
      final r = calculator.calculateBill(units: 80, tariff: simpleTariff);
      expect(r.slabCharges, hasLength(1));
      expect(r.energyCharges, 800);
      expect(r.total, 800);
      expect(r.averageCostPerUnit, 10);
    });

    test('exact slab boundary does not spill into next slab', () {
      final r = calculator.calculateBill(units: 100, tariff: simpleTariff);
      expect(r.slabCharges, hasLength(1));
      expect(r.energyCharges, 1000);
    });

    test('units across slabs are charged progressively', () {
      final r = calculator.calculateBill(units: 250, tariff: simpleTariff);
      expect(r.slabCharges.map((s) => s.units), [100, 100, 50]);
      expect(r.slabCharges.map((s) => s.amount), [1000, 2000, 1500]);
      expect(r.energyCharges, 4500);
      expect(r.slabCharges.last.fromUnits, 200);
      expect(r.slabCharges.last.toUnits, isNull);
    });

    test('fractional units are supported', () {
      final r = calculator.calculateBill(units: 100.5, tariff: simpleTariff);
      expect(r.energyCharges, closeTo(1010, 0.001));
    });

    test('zero units gives zero energy and only fixed charges', () {
      final tariff = simpleTariff.copyWith(
        fixedChargePerMonth: 50,
        charges: const [ChargeItem(name: 'Fee', basis: ChargeBasis.fixedAmount, value: 35, isTax: true)],
      );
      final r = calculator.calculateBill(units: 0, tariff: tariff);
      expect(r.slabCharges, isEmpty);
      expect(r.energyCharges, 0);
      expect(r.total, 85);
      expect(r.averageCostPerUnit, 0);
    });
  });

  group('single slab mode', () {
    test('all units charged at the rate of the slab reached', () {
      final tariff = simpleTariff.copyWith(slabMode: SlabMode.singleSlab);
      final r = calculator.calculateBill(units: 150, tariff: tariff);
      expect(r.slabCharges, hasLength(1));
      expect(r.slabCharges.single.ratePerUnit, 20);
      expect(r.energyCharges, 3000);
    });

    test('top open-ended slab', () {
      final tariff = simpleTariff.copyWith(slabMode: SlabMode.singleSlab);
      final r = calculator.calculateBill(units: 1000, tariff: tariff);
      expect(r.energyCharges, 30000);
    });
  });

  group('charges and taxes', () {
    test('each charge basis is applied correctly and taxes use the full subtotal', () {
      final tariff = simpleTariff.copyWith(
        fixedChargePerMonth: 100,
        charges: const [
          ChargeItem(name: 'Surcharge', basis: ChargeBasis.perUnit, value: 2, isTax: false),
          ChargeItem(name: 'Adj', basis: ChargeBasis.percentOfSubtotal, value: 10, isTax: false),
          ChargeItem(name: 'Duty', basis: ChargeBasis.percentOfEnergy, value: 1.5, isTax: true),
          ChargeItem(name: 'GST', basis: ChargeBasis.percentOfSubtotal, value: 18, isTax: true),
          ChargeItem(name: 'TV', basis: ChargeBasis.fixedAmount, value: 35, isTax: true),
        ],
      );
      final r = calculator.calculateBill(units: 150, tariff: tariff);
      // Energy: 100*10 + 50*20 = 2000.
      expect(r.energyCharges, 2000);
      expect(r.fixedCharges, 100);
      // Surcharge 150*2 = 300; Adj = 10% of (2000 + 100) = 210.
      expect(r.additionalCharges.map((c) => c.amount), [300, 210]);
      expect(r.totalAdditionalCharges, 510);
      // Pre-tax subtotal 2610. Duty 1.5% of 2000 = 30; GST 18% of 2610 = 469.8; TV 35.
      expect(r.subtotalBeforeTax, 2610);
      expect(r.taxes.map((c) => c.amount), [30, 469.8, 35]);
      expect(r.totalTaxes, closeTo(534.8, 0.001));
      expect(r.total, closeTo(3144.8, 0.001));
      expect(r.averageCostPerUnit, closeTo(3144.8 / 150, 0.0001));
    });

    test('amounts are rounded to 2 decimals', () {
      const tariff = TariffConfig(
        connectionType: ConnectionType.commercial,
        slabMode: SlabMode.progressive,
        slabs: [TariffSlab(upToUnits: null, ratePerUnit: 1.111)],
        fixedChargePerMonth: 0,
        charges: [],
      );
      final r = calculator.calculateBill(units: 3, tariff: tariff);
      expect(r.energyCharges, 3.33);
    });
  });

  group('default tariffs', () {
    test('defaults are valid configurations', () {
      for (final tariff in DefaultTariffs.all.values) {
        expect(tariff.validate(), isNull, reason: tariff.connectionType.name);
      }
    });

    test('residential 250 units matches hand calculation', () {
      final r = calculator.calculateBill(units: 250, tariff: DefaultTariffs.residential);
      expect(r.energyCharges, closeTo(2244 + 2891 + 1655, 0.001));
      expect(r.totalAdditionalCharges, closeTo(807.5, 0.001));
      expect(r.totalTaxes, closeTo(101.85 + 1367.55 + 35, 0.001));
      expect(r.total, closeTo(9101.9, 0.001));
    });
  });

  group('invalid input', () {
    test('negative, NaN and infinite units throw', () {
      for (final units in [-1.0, double.nan, double.infinity]) {
        expect(
          () => calculator.calculateBill(units: units, tariff: simpleTariff),
          throwsArgumentError,
        );
      }
    });

    test('inconsistent tariff configuration throws', () {
      final bad = simpleTariff.copyWith(slabs: const [
        TariffSlab(upToUnits: 200, ratePerUnit: 10),
        TariffSlab(upToUnits: 100, ratePerUnit: 20),
        TariffSlab(upToUnits: null, ratePerUnit: 30),
      ]);
      expect(bad.validate(), 'errSlabOrder');
      expect(() => calculator.calculateBill(units: 10, tariff: bad), throwsArgumentError);
    });

    test('last slab must be open-ended and slabs non-empty', () {
      expect(simpleTariff.copyWith(slabs: const []).validate(), 'errNoSlabs');
      expect(
        simpleTariff.copyWith(slabs: const [TariffSlab(upToUnits: 100, ratePerUnit: 1)]).validate(),
        'errLastSlabOpen',
      );
    });
  });

  test('BillResult and TariffConfig survive a JSON round trip', () {
    final tariff = TariffConfig.fromJson(DefaultTariffs.residential.toJson());
    final r = calculator.calculateBill(units: 333, tariff: tariff);
    final copy = calculator.calculateBill(units: 333, tariff: DefaultTariffs.residential);
    expect(r.total, copy.total);
  });
}
