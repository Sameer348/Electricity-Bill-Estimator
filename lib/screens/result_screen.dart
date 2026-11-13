import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/bill_result.dart';
import '../models/saved_estimate.dart';
import '../models/tariff_config.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result, this.savedEstimate});

  final BillResult result;

  /// Set when opened from history (already saved).
  final SavedEstimate? savedEstimate;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late bool _saved = widget.savedEstimate != null;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.appRead.saveEstimate(widget.result);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    showSnack(context, context.tr('estimateSaved'));
  }

  String _shareText(BuildContext context) {
    final r = widget.result;
    final other = r.fixedCharges + r.totalAdditionalCharges;
    return [
      context.tr('shareTitle'),
      '${context.tr('shareUnits')}: ${Fmt.units(r.units)}',
      '${context.tr('energyCharges')}: ${Fmt.pkr(r.energyCharges)}',
      if (other > 0) '${context.tr('shareOther')}: ${Fmt.pkr(other)}',
      '${context.tr('taxes')}: ${Fmt.pkr(r.totalTaxes)}',
      '${context.tr('shareTotal')}: ${Fmt.pkr(r.total)}',
      context.tr('shareFooter'),
    ].join('\n');
  }

  Future<void> _share(BuildContext anchorContext) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: _shareText(context),
      subject: context.tr('shareTitle'),
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('resultTitle'))),
      body: SafeArea(
        child: PageList(
          children: [
            // Headline total.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('estimatedTotal'),
                    style: theme.textTheme.titleSmall?.copyWith(color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      Fmt.pkr(r.total),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: context.tr('unitsConsumed'),
                          value: '${Fmt.units(r.units)} kWh',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: context.tr('costPerUnit'),
                          value: 'PKR ${Fmt.rate(r.averageCostPerUnit)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.electrical_services_outlined, size: 18),
                        label: Text(context.tr(r.connectionType.labelKey)),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text(context.tr(
                          r.slabMode == SlabMode.progressive ? 'slabModeProgressive' : 'slabModeSingle',
                        )),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const DisclaimerCard(showLong: false),
            const SizedBox(height: 12),
            SectionCard(
              title: context.tr('slabBreakdown'),
              child: _SlabTable(slabs: r.slabCharges),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: context.tr('chargesSummary'),
              child: Column(
                children: [
                  AmountRow(label: context.tr('energyCharges'), value: Fmt.pkr2(r.energyCharges)),
                  if (r.fixedCharges > 0)
                    AmountRow(label: context.tr('fixedCharges'), value: Fmt.pkr2(r.fixedCharges)),
                  if (r.additionalCharges.isNotEmpty) ...[
                    const Divider(height: 20),
                    AmountRow(
                      label: context.tr('additionalCharges'),
                      value: Fmt.pkr2(r.totalAdditionalCharges),
                    ),
                    for (final line in r.additionalCharges)
                      AmountRow(label: '  • ${line.name}', value: Fmt.pkr2(line.amount), muted: true),
                  ],
                  if (r.taxes.isNotEmpty) ...[
                    const Divider(height: 20),
                    AmountRow(label: context.tr('taxes'), value: Fmt.pkr2(r.totalTaxes)),
                    for (final line in r.taxes)
                      AmountRow(label: '  • ${line.name}', value: Fmt.pkr2(line.amount), muted: true),
                  ],
                  const Divider(height: 20),
                  AmountRow(label: context.tr('estimatedTotal'), value: Fmt.pkr2(r.total), emphasize: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const DisclaimerCard(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (_saved || _saving) ? null : _save,
              icon: Icon(_saved ? Icons.check_circle_outline : Icons.bookmark_add_outlined),
              label: Text(context.tr(_saved ? 'saved' : 'saveEstimate')),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('calculateAgain'), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(
                    // Builder gives the share sheet an anchor on tablets.
                    builder: (buttonContext) => OutlinedButton.icon(
                      onPressed: () => _share(buttonContext),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(context.tr('shareResult'), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SlabTable extends StatelessWidget {
  const _SlabTable({required this.slabs});

  final List<SlabCharge> slabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final body = theme.textTheme.bodyMedium;

    TableRow row(List<String> cells, TextStyle? style) => TableRow(
          children: [
            for (var i = 0; i < cells.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(cells[i], style: style, textAlign: i == 0 ? TextAlign.start : TextAlign.end),
              ),
          ],
        );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        row([
          context.tr('slabCol'),
          context.tr('unitsCol'),
          context.tr('rateCol'),
          context.tr('amountCol'),
        ], header),
        for (final slab in slabs)
          row([
            Fmt.slabRange(slab.fromUnits, slab.toUnits),
            Fmt.units(slab.units),
            Fmt.rate(slab.ratePerUnit),
            Fmt.pkr(slab.amount).replaceFirst('PKR ', ''),
          ], body),
      ],
    );
  }
}
