import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/app_strings.dart';
import '../models/connection_type.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'tariff_editor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearHistory(BuildContext context) async {
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

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: context.tr('appTitle'),
      applicationVersion: '${context.tr('version')} ${AppInfo.version}',
      applicationIcon: const AppLogo(size: 48),
      children: [
        Text(context.tr('aboutBody')),
        const SizedBox(height: 12),
        Text(context.tr('privacyBody')),
        const SizedBox(height: 12),
        Text(context.tr('longDisclaimer'), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final settings = app.settings;
    final theme = Theme.of(context);

    Widget label(String key) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(context.tr(key), style: theme.textTheme.labelLarge),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: SafeArea(
        child: PageList(
          children: [
            SectionCard(
              title: context.tr('general'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label('language'),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'ur', label: Text('اردو')),
                    ],
                    selected: {settings.languageCode},
                    onSelectionChanged: (s) => app.updateSettings(settings.copyWith(languageCode: s.first)),
                  ),
                  const SizedBox(height: 16),
                  label('theme'),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
                        label: Text(context.tr('themeSystem')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(context.tr('themeLight')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(context.tr('themeDark')),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => app.updateSettings(settings.copyWith(themeMode: s.first)),
                  ),
                  const SizedBox(height: 16),
                  label('defaultTariff'),
                  SegmentedButton<ConnectionType>(
                    showSelectedIcon: false,
                    segments: [
                      for (final type in ConnectionType.values)
                        ButtonSegment(value: type, label: Text(context.tr(type.labelKey))),
                    ],
                    selected: {settings.defaultConnectionType},
                    onSelectionChanged: (s) =>
                        app.updateSettings(settings.copyWith(defaultConnectionType: s.first)),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(context.tr('currency')),
                    subtitle: Text(context.tr('currencyPkr')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: context.tr('data'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(context.tr('manageTariffs')),
                    subtitle: Text(context.tr('manageTariffsSubtitle')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TariffEditorScreen()),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
                    title: Text(context.tr('clearHistory')),
                    enabled: app.history.isNotEmpty,
                    onTap: () => _clearHistory(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(context.tr('about')),
                    subtitle: Text('${context.tr('version')} ${AppInfo.version}'),
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const DisclaimerCard(),
          ],
        ),
      ),
    );
  }
}
