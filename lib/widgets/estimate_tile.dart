import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import '../models/connection_type.dart';
import '../models/saved_estimate.dart';

/// One history entry: date, units and estimated bill.
class EstimateTile extends StatelessWidget {
  const EstimateTile({super.key, required this.estimate, this.onTap, this.onDelete});

  final SavedEstimate estimate;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = estimate.result;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isResidential = result.connectionType == ConnectionType.residential;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Icon(isResidential ? Icons.home_outlined : Icons.storefront_outlined),
      ),
      title: Text(
        '${Fmt.units(result.units)} ${context.tr('units')} · ${context.tr(result.connectionType.labelKey)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(Fmt.date(estimate.savedAt, languageCode)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Fmt.pkr(result.total),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: context.tr('delete'),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
