import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../models/saved_estimate.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/estimate_tile.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _delete(BuildContext context, SavedEstimate estimate) async {
    final app = context.appRead;
    final message = context.tr('estimateDeleted');
    final undoLabel = context.tr('undo');
    await app.deleteEstimate(estimate.id);
    if (!context.mounted) return;
    showSnack(
      context,
      message,
      action: SnackBarAction(label: undoLabel, onPressed: () => app.restoreEstimate(estimate)),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.tr('clearHistory'),
      message: context.tr('clearHistoryConfirm'),
      confirmLabel: context.tr('clear'),
    );
    if (!confirmed || !context.mounted) return;
    await context.appRead.clearHistory();
    if (context.mounted) showSnack(context, context.tr('historyCleared'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = context.app.history;

    return PageList(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('historyTitle'),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (history.isNotEmpty)
              TextButton.icon(
                onPressed: () => _clearAll(context),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(context.tr('clearHistory')),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.tr('noHistory'),
            message: context.tr('noHistoryHint'),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                children: [
                  for (final estimate in history)
                    Dismissible(
                      key: ValueKey(estimate.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) => _delete(context, estimate),
                      child: EstimateTile(
                        estimate: estimate,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ResultScreen(result: estimate.result, savedEstimate: estimate),
                        )),
                        onDelete: () => _delete(context, estimate),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
