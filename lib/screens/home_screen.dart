import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../core/validators.dart';
import '../models/connection_type.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/estimate_tile.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.unitsController, required this.onViewAllHistory});

  final TextEditingController unitsController;
  final VoidCallback onViewAllHistory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  ConnectionType? _connectionType;
  bool _showTariffError = false;

  @override
  void initState() {
    super.initState();
    _connectionType = context.appRead.settings.defaultConnectionType;
  }

  void _calculate() {
    final unitsValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTariffError = _connectionType == null);
    if (!unitsValid || _connectionType == null) return;

    FocusScope.of(context).unfocus();
    final units = parseNumber(widget.unitsController.text)!;
    try {
      final result = context.appRead.calculate(units, _connectionType!);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    } on ArgumentError {
      showSnack(context, context.tr('errFixForm'));
    }
  }

  String? _unitsError(String? value) {
    final key = validateUnits(value);
    if (key == null) return null;
    return context.tr(key, {'max': Fmt.units(InputLimits.maxUnits)});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.app;
    final recent = app.history.take(3).toList();

    return PageList(
      children: [
        Row(
          children: [
            const AppLogo(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('appTitle'),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('appSubtitle'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('settings'),
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: widget.unitsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _calculate(),
                  style: theme.textTheme.headlineSmall,
                  decoration: InputDecoration(
                    labelText: context.tr('unitsLabel'),
                    hintText: context.tr('unitsHint'),
                    prefixIcon: const Icon(Icons.electric_meter_outlined),
                    suffixText: 'kWh',
                  ),
                  validator: _unitsError,
                ),
                const SizedBox(height: 20),
                Text(context.tr('connectionType'), style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ConnectionType>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ConnectionType.residential,
                      icon: const Icon(Icons.home_outlined),
                      label: Text(context.tr('residential')),
                    ),
                    ButtonSegment(
                      value: ConnectionType.commercial,
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text(context.tr('commercial')),
                    ),
                  ],
                  selected: {?_connectionType},
                  onSelectionChanged: (selection) => setState(() {
                    _connectionType = selection.isEmpty ? null : selection.first;
                    if (_connectionType != null) _showTariffError = false;
                  }),
                ),
                if (_showTariffError) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.tr('errSelectTariff'),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(context.tr('calculateBill')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('shortDisclaimer'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: context.tr('recentCalculations'),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          trailing: recent.isEmpty
              ? null
              : TextButton(onPressed: widget.onViewAllHistory, child: Text(context.tr('viewAll'))),
          child: recent.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: context.tr('noHistory'),
                  message: context.tr('noHistoryHint'),
                )
              : Column(
                  children: [
                    for (final estimate in recent)
                      EstimateTile(
                        estimate: estimate,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ResultScreen(result: estimate.result, savedEstimate: estimate),
                        )),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
