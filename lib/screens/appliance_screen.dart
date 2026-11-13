import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../core/validators.dart';
import '../data/appliance_presets.dart';
import '../models/appliance.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';

class ApplianceScreen extends StatefulWidget {
  const ApplianceScreen({super.key, required this.onUseUnits});

  /// Sends the combined monthly kWh to the bill calculator.
  final ValueChanged<double> onUseUnits;

  @override
  State<ApplianceScreen> createState() => _ApplianceScreenState();
}

class _ApplianceScreenState extends State<ApplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _watts = TextEditingController();
  final _hours = TextEditingController();
  final _days = TextEditingController(text: '30');
  final List<Appliance> _appliances = [];

  @override
  void dispose() {
    for (final c in [_name, _watts, _hours, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(AppliancePreset preset) {
    setState(() {
      _name.text = context.tr(preset.nameKey);
      _watts.text = Fmt.units(preset.watts).replaceAll(',', '');
      _hours.text = Fmt.units(preset.hoursPerDay);
      _days.text = preset.daysPerMonth.toString();
    });
    _formKey.currentState?.validate();
  }

  void _add() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _appliances.add(Appliance(
        name: _name.text.trim(),
        watts: parseNumber(_watts.text)!,
        hoursPerDay: parseNumber(_hours.text)!,
        daysPerMonth: parseNumber(_days.text)!.round(),
      ));
      _name.clear();
      _watts.clear();
      _hours.clear();
    });
    _formKey.currentState?.reset();
    _days.text = '30';
  }

  String? Function(String?) _rangeValidator(double min, double max, String errorKey) {
    return (value) {
      if (value == null || value.trim().isEmpty) return context.tr('errRequired');
      final number = parseNumber(value);
      if (number == null || number < min || number > max) return context.tr(errorKey);
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.app;
    final tariffType = app.settings.defaultConnectionType;
    final totalKwh = _appliances.fold<double>(0, (sum, a) => sum + a.monthlyKwh);
    // Average all-in rate at the combined usage, used to price each appliance.
    final averageRate = totalKwh > 0 ? app.calculate(totalKwh, tariffType).averageCostPerUnit : 0.0;
    final numberFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      LengthLimitingTextInputFormatter(7),
    ];

    return PageList(
      children: [
        Text(
          context.tr('applianceTitle'),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('applianceSubtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: context.tr('presets'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in appliancePresets)
                ActionChip(
                  label: Text(context.tr(preset.nameKey)),
                  tooltip: '${Fmt.units(preset.watts)} W',
                  onPressed: () => _applyPreset(preset),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: InputDecoration(
                    labelText: context.tr('applianceName'),
                    prefixIcon: const Icon(Icons.devices_other_outlined),
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('errRequired') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _watts,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: numberFormatter,
                  decoration: InputDecoration(labelText: context.tr('wattage'), suffixText: 'W'),
                  validator: _rangeValidator(1, InputLimits.maxWatts, 'errWattage'),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hours,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: numberFormatter,
                        decoration: InputDecoration(labelText: context.tr('hoursPerDay')),
                        validator: _rangeValidator(0.1, InputLimits.maxHoursPerDay, 'errHours'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _days,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                        decoration: InputDecoration(labelText: context.tr('daysPerMonth')),
                        validator: _rangeValidator(1, InputLimits.maxDaysPerMonth.toDouble(), 'errDays'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.tr('addAppliance')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.tr('yourAppliances'),
          child: _appliances.isEmpty
              ? EmptyState(icon: Icons.kitchen_outlined, title: context.tr('applianceEmpty'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _appliances.length; i++)
                      _ApplianceRow(
                        appliance: _appliances[i],
                        cost: _appliances[i].monthlyKwh * averageRate,
                        onRemove: () => setState(() => _appliances.removeAt(i)),
                      ),
                    const Divider(height: 24),
                    AmountRow(
                      label: '${context.tr('totalUsage')} · ${context.tr('monthlyKwh')}',
                      value: '${Fmt.units(totalKwh)} kWh',
                      emphasize: true,
                    ),
                    AmountRow(
                      label: context.tr('estimatedMonthlyCost'),
                      value: Fmt.pkr(totalKwh * averageRate),
                      emphasize: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('applianceCostNote', {'tariff': context.tr(tariffType.labelKey)}),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: totalKwh > 0 && totalKwh <= InputLimits.maxUnits
                          ? () => widget.onUseUnits(totalKwh)
                          : null,
                      icon: const Icon(Icons.calculate_outlined),
                      label: Text(context.tr('useInBillCalculator')),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ApplianceRow extends StatelessWidget {
  const _ApplianceRow({required this.appliance, required this.cost, required this.onRemove});

  final Appliance appliance;
  final double cost;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appliance.name, style: theme.textTheme.titleSmall),
                Text(
                  '${Fmt.units(appliance.watts)} W × ${Fmt.units(appliance.hoursPerDay)} h × ${appliance.daysPerMonth} d',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${Fmt.units(appliance.monthlyKwh)} kWh', style: theme.textTheme.bodyMedium),
              Text(Fmt.pkr(cost), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          IconButton(
            tooltip: context.tr('remove'),
            icon: const Icon(Icons.close_rounded),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
