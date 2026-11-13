import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';

/// Max content width so layouts stay readable on tablets / landscape.
const double kMaxContentWidth = 640;

/// Centered, width-constrained scrolling page body.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: ListView(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: children,
        ),
      ),
    );
  }
}

/// Rounded lightning-bolt mark used as the in-app logo.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Electricity Bill Estimator logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E63F0), Color(0xFF1437A8)],
          ),
        ),
        child: Icon(Icons.bolt_rounded, color: AppTheme.bolt, size: size * 0.66),
      ),
    );
  }
}

/// Card with an optional heading.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.child, this.padding});

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(title!, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Label/value row used in breakdowns.
class AmountRow extends StatelessWidget {
  const AmountRow({super.key, required this.label, required this.value, this.emphasize = false, this.muted = false});

  final String label;
  final String value;
  final bool emphasize;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = emphasize ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    final color = muted ? theme.colorScheme.onSurfaceVariant : null;
    final weight = emphasize ? FontWeight.w700 : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: base?.copyWith(color: color, fontWeight: weight))),
          const SizedBox(width: 12),
          Text(value, style: base?.copyWith(color: color, fontWeight: weight ?? FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Info banner reminding users results are estimates.
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key, this.showLong = true});

  final bool showLong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.onTertiaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('shortDisclaimer'),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                if (showLong) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.tr('longDisclaimer'),
                    style: textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size(64, 40),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
