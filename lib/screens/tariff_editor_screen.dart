import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../core/validators.dart';
import '../models/connection_type.dart';
import '../models/tariff_config.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';

/// Lets users update slab rates, taxes and surcharges without a code change.
class TariffEditorScreen extends StatefulWidget {
  const TariffEditorScreen({super.key});

  @override
  State<TariffEditorScreen> createState() => _TariffEditorScreenState();
}

class _SlabDraft {
  _SlabDraft(TariffSlab slab)
      : upTo = TextEditingController(text: slab.upToUnits?.toString() ?? ''),
        rate = TextEditingController(text: _num(slab.ratePerUnit));

  final TextEditingController upTo;
  final TextEditingController rate;

  void dispose() {
    upTo.dispose();
    rate.dispose();
  }
}

class _ChargeDraft {
  _ChargeDraft(ChargeItem charge)
      : name = TextEditingController(text: charge.name),
        value = TextEditingController(text: _num(charge.value)),
        basis = charge.basis,
        isTax = charge.isTax;

  final TextEditingController name;
  final TextEditingController value;
  ChargeBasis basis;
  bool isTax;

  void dispose() {
    name.dispose();
    value.dispose();
  }
}

String _num(double value) => Fmt.units(value).replaceAll(',', '');

class _TariffEditorScreenState extends State<TariffEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  ConnectionType _type = ConnectionType.residential;
  SlabMode _slabMode = SlabMode.progressive;
  final List<_SlabDraft> _slabs = [];
  final List<_ChargeDraft> _charges = [];
  final _fixedCharge = TextEditingController();
  final _note = TextEditingController();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _type = context.appRead.settings.defaultConnectionType;
    _loadFrom(context.appRead.tariffFor(_type));
  }

  @override
  void dispose() {
    _disposeDrafts();
    _fixedCharge.dispose();
    _note.dispose();
    super.dispose();
  }

  void _disposeDrafts() {
    for (final s in _slabs) {
      s.dispose();
    }
    for (final c in _charges) {
      c.dispose();
    }
    _slabs.clear();
    _charges.clear();
  }

  void _loadFrom(TariffConfig config) {
    _disposeDrafts();
    _slabMode = config.slabMode;
    _slabs.addAll(config.slabs.map(_SlabDraft.new));
    _charges.addAll(config.charges.map(_ChargeDraft.new));
    _fixedCharge.text = _num(config.fixedChargePerMonth);
    _note.text = config.note;
    _dirty = false;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return showConfirmDialog(
      context,
      title: context.tr('discardTitle'),
      message: context.tr('discardBody'),
      confirmLabel: context.tr('discard'),
    );
  }

  Future<void> _switchType(ConnectionType type) async {
    if (type == _type || !await _confirmDiscard() || !mounted) return;
    setState(() {
      _type = type;
      _loadFrom(context.appRead.tariffFor(type));
    });
  }

  void _addSlab() {
    setState(() {
      final last = _slabs.last;
      final previousUpper = _slabs.length > 1 ? int.tryParse(_slabs[_slabs.length - 2].upTo.text) ?? 0 : 0;
      last.upTo.text = (previousUpper + 100).toString();
      _slabs.add(_SlabDraft(TariffSlab(upToUnits: null, ratePerUnit: parseNumber(last.rate.text) ?? 0)));
      _dirty = true;
    });
  }

  void _removeSlab(int index) {
    setState(() {
      _slabs.removeAt(index).dispose();
      _slabs.last.upTo.clear();
      _dirty = true;
    });
  }

  void _addCharge() {
    setState(() {
      _charges.add(_ChargeDraft(const ChargeItem(
        name: '',
        basis: ChargeBasis.fixedAmount,
        value: 0,
        isTax: false,
      )));
      _dirty = true;
    });
  }

  TariffConfig _buildConfig() {
    return TariffConfig(
      connectionType: _type,
      slabMode: _slabMode,
      slabs: [
        for (var i = 0; i < _slabs.length; i++)
          TariffSlab(
            upToUnits: i == _slabs.length - 1 ? null : int.parse(_slabs[i].upTo.text.trim()),
            ratePerUnit: parseNumber(_slabs[i].rate.text)!,
          ),
      ],
      fixedChargePerMonth: parseNumber(_fixedCharge.text) ?? 0,
      charges: [
        for (final c in _charges)
          ChargeItem(
            name: c.name.text.trim(),
            basis: c.basis,
            value: parseNumber(c.value.text)!,
            isTax: c.isTax,
          ),
      ],
      note: _note.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      showSnack(context, context.tr('errFixForm'));
      return;
    }
    final config = _buildConfig();
    final error = config.validate();
    if (error != null) {
      showSnack(context, context.tr(error));
      return;
    }
    await context.appRead.updateTariff(config);
    if (!mounted) return;
    setState(() => _dirty = false);
    showSnack(context, context.tr('tariffSaved'));
  }

  Future<void> _reset() async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.tr('resetDefaults'),
      message: context.tr('resetConfirm', {'type': context.tr(_type.labelKey)}),
      confirmLabel: context.tr('reset'),
    );
    if (!confirmed || !mounted) return;
    await context.appRead.resetTariff(_type);
    if (!mounted) return;
    setState(() => _loadFrom(context.appRead.tariffFor(_type)));
  }

  String? _nonNegative(String? value) {
    final number = parseNumber(value);
    if (number == null || number < 0) return context.tr('errRate');
    return null;
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? context.tr('errRequired') : null;

  String? _upperBound(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return context.tr('errRate');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.app;
    final decimalInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('tariffEditorTitle')),
          actions: [
            IconButton(
              tooltip: context.tr('resetDefaults'),
              icon: const Icon(Icons.restore_rounded),
              onPressed: app.isCustomTariff(_type) ? _reset : null,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _dirty ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(context.tr('save')),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: PageList(
            children: [
              SegmentedButton<ConnectionType>(
                showSelectedIcon: false,
                segments: [
                  for (final type in ConnectionType.values)
                    ButtonSegment(value: type, label: Text(context.tr(type.labelKey))),
                ],
                selected: {_type},
                onSelectionChanged: (s) => _switchType(s.first),
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr(app.isCustomTariff(_type) ? 'customRates' : 'defaultRates')} · ${context.tr('tariffEditorInfo')}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: context.tr('slabMode'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<SlabMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: SlabMode.progressive, label: Text(context.tr('slabModeProgressive'))),
                        ButtonSegment(value: SlabMode.singleSlab, label: Text(context.tr('slabModeSingle'))),
                      ],
                      selected: {_slabMode},
                      onSelectionChanged: (s) => setState(() {
                        _slabMode = s.first;
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(_slabMode == SlabMode.progressive ? 'slabModeProgressiveHelp' : 'slabModeSingleHelp'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: context.tr('slabs'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _slabs.length; i++)
                      Padding(
                        key: ObjectKey(_slabs[i]),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: i == _slabs.length - 1
                                  ? InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: context.tr('slabLabel', {'n': '${i + 1}'}),
                                      ),
                                      child: Text(context.tr('andAbove')),
                                    )
                                  : TextFormField(
                                      controller: _slabs[i].upTo,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        labelText: '${context.tr('slabLabel', {'n': '${i + 1}'})} · ${context.tr('upToUnits')}',
                                      ),
                                      validator: _upperBound,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _slabs[i].rate,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: decimalInput,
                                decoration: InputDecoration(labelText: context.tr('ratePerUnit')),
                                validator: _nonNegative,
                              ),
                            ),
                            IconButton(
                              tooltip: context.tr('removeSlab'),
                              onPressed: _slabs.length > 1 ? () => _removeSlab(i) : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _addSlab,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(context.tr('addSlab')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: TextFormField(
                  controller: _fixedCharge,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInput,
                  decoration: InputDecoration(labelText: context.tr('fixedChargeLabel')),
                  validator: _nonNegative,
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: context.tr('charges'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _charges.length; i++)
                      _ChargeEditor(
                        key: ObjectKey(_charges[i]),
                        draft: _charges[i],
                        decimalInput: decimalInput,
                        requiredValidator: _required,
                        valueValidator: _nonNegative,
                        onChanged: () => setState(() => _dirty = true),
                        onRemove: () => setState(() {
                          _charges.removeAt(i).dispose();
                          _dirty = true;
                        }),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _addCharge,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(context.tr('addCharge')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: TextFormField(
                  controller: _note,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: InputDecoration(labelText: context.tr('ratesNote')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChargeEditor extends StatelessWidget {
  const _ChargeEditor({
    super.key,
    required this.draft,
    required this.decimalInput,
    required this.requiredValidator,
    required this.valueValidator,
    required this.onChanged,
    required this.onRemove,
  });

  final _ChargeDraft draft;
  final List<TextInputFormatter> decimalInput;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> valueValidator;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  static const _basisKeys = {
    ChargeBasis.fixedAmount: 'basisFixedAmount',
    ChargeBasis.perUnit: 'basisPerUnit',
    ChargeBasis.percentOfEnergy: 'basisPercentOfEnergy',
    ChargeBasis.percentOfSubtotal: 'basisPercentOfSubtotal',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: draft.name,
                  decoration: InputDecoration(labelText: context.tr('chargeName')),
                  validator: requiredValidator,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: draft.value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInput,
                  decoration: InputDecoration(labelText: context.tr('chargeValue')),
                  validator: valueValidator,
                ),
              ),
              IconButton(
                tooltip: context.tr('remove'),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: DropdownButtonFormField<ChargeBasis>(
              initialValue: draft.basis,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.tr('basis')),
              items: [
                for (final entry in _basisKeys.entries)
                  DropdownMenuItem(value: entry.key, child: Text(context.tr(entry.value))),
              ],
              onChanged: (value) {
                if (value == null) return;
                draft.basis = value;
                onChanged();
              },
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(end: 4),
            title: Text(context.tr('isTax')),
            value: draft.isTax,
            onChanged: (value) {
              draft.isTax = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
