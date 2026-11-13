import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_strings.dart';
import 'core/app_theme.dart';
import 'screens/root_shell.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';

class BillEstimatorApp extends StatelessWidget {
  const BillEstimatorApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          title: 'Electricity Bill Estimator',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.settings.themeMode,
          locale: controller.locale,
          supportedLocales: [
            for (final code in AppStrings.supportedLanguageCodes) Locale(code),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const RootShell(),
        ),
      ),
    );
  }
}
