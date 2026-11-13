import '../models/connection_type.dart';
import '../models/tariff_config.dart';

/// Built-in starting tariffs.
///
/// These are ILLUSTRATIVE ESTIMATES loosely based on publicly reported
/// NEPRA/DISCO rates and are NOT official. Update them here (for new installs)
/// or via Settings → Manage tariff rates (per device). The calculation engine
/// reads only from [TariffConfig], so no other code needs to change.
class DefaultTariffs {
  const DefaultTariffs._();

  static const String _note = 'Sample rates for estimation only. Verify with your DISCO bill.';

  static const TariffConfig residential = TariffConfig(
    connectionType: ConnectionType.residential,
    slabMode: SlabMode.progressive,
    slabs: [
      TariffSlab(upToUnits: 100, ratePerUnit: 22.44),
      TariffSlab(upToUnits: 200, ratePerUnit: 28.91),
      TariffSlab(upToUnits: 300, ratePerUnit: 33.10),
      TariffSlab(upToUnits: 400, ratePerUnit: 37.99),
      TariffSlab(upToUnits: 500, ratePerUnit: 40.20),
      TariffSlab(upToUnits: 700, ratePerUnit: 42.20),
      TariffSlab(upToUnits: null, ratePerUnit: 47.69),
    ],
    fixedChargePerMonth: 0,
    charges: [
      ChargeItem(
        name: 'FC surcharge',
        basis: ChargeBasis.perUnit,
        value: 3.23,
        isTax: false,
      ),
      ChargeItem(
        name: 'Electricity duty',
        basis: ChargeBasis.percentOfEnergy,
        value: 1.5,
        isTax: true,
      ),
      ChargeItem(
        name: 'GST',
        basis: ChargeBasis.percentOfSubtotal,
        value: 18,
        isTax: true,
      ),
      ChargeItem(
        name: 'PTV fee',
        basis: ChargeBasis.fixedAmount,
        value: 35,
        isTax: true,
      ),
    ],
    note: _note,
  );

  static const TariffConfig commercial = TariffConfig(
    connectionType: ConnectionType.commercial,
    slabMode: SlabMode.progressive,
    slabs: [
      TariffSlab(upToUnits: null, ratePerUnit: 52.00),
    ],
    fixedChargePerMonth: 0,
    charges: [
      ChargeItem(
        name: 'FC surcharge',
        basis: ChargeBasis.perUnit,
        value: 3.23,
        isTax: false,
      ),
      ChargeItem(
        name: 'Electricity duty',
        basis: ChargeBasis.percentOfEnergy,
        value: 1.5,
        isTax: true,
      ),
      ChargeItem(
        name: 'GST',
        basis: ChargeBasis.percentOfSubtotal,
        value: 18,
        isTax: true,
      ),
      ChargeItem(
        name: 'PTV fee',
        basis: ChargeBasis.fixedAmount,
        value: 60,
        isTax: true,
      ),
    ],
    note: _note,
  );

  static TariffConfig forType(ConnectionType type) => switch (type) {
        ConnectionType.residential => residential,
        ConnectionType.commercial => commercial,
      };

  static Map<ConnectionType, TariffConfig> get all =>
      {for (final type in ConnectionType.values) type: forType(type)};
}
