import 'package:electricity_bill_estimator/app.dart';
import 'package:electricity_bill_estimator/models/connection_type.dart';
import 'package:electricity_bill_estimator/models/tariff_config.dart';
import 'package:electricity_bill_estimator/services/storage_service.dart';
import 'package:electricity_bill_estimator/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> _controller() async {
  SharedPreferences.setMockInitialValues({});
  final controller = AppController(storage: await PrefsStorageService.create());
  await controller.load();
  return controller;
}

void main() {
  setUpAll(() => initializeDateFormatting());

  test('history, settings and tariffs persist across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await PrefsStorageService.create();
    final controller = AppController(storage: storage);
    await controller.load();

    final result = controller.calculate(250, ConnectionType.residential);
    await controller.saveEstimate(result);
    await controller.updateSettings(
      controller.settings.copyWith(languageCode: 'ur', themeMode: ThemeMode.dark),
    );
    final custom = controller
        .tariffFor(ConnectionType.commercial)
        .copyWith(slabs: const [TariffSlab(upToUnits: null, ratePerUnit: 99)]);
    await controller.updateTariff(custom);

    final reloaded = AppController(storage: storage);
    await reloaded.load();
    expect(reloaded.history, hasLength(1));
    expect(reloaded.history.first.result.total, result.total);
    expect(reloaded.settings.languageCode, 'ur');
    expect(reloaded.settings.themeMode, ThemeMode.dark);
    expect(reloaded.tariffFor(ConnectionType.commercial).slabs.single.ratePerUnit, 99);
    expect(reloaded.isCustomTariff(ConnectionType.residential), isFalse);

    await reloaded.resetTariff(ConnectionType.commercial);
    await reloaded.clearHistory();
    expect(reloaded.isCustomTariff(ConnectionType.commercial), isFalse);
    expect(reloaded.history, isEmpty);
  });

  testWidgets('validates input, calculates and saves an estimate', (tester) async {
    final controller = await _controller();
    await tester.pumpWidget(BillEstimatorApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Electricity Bill Estimator'), findsOneWidget);

    // Empty units shows a friendly validation message.
    await tester.tap(find.text('Calculate Bill'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter the units consumed.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('Calculate Bill'));
    await tester.pumpAndSettle();
    expect(find.text('Units cannot be negative.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.tap(find.text('Calculate Bill'));
    await tester.pumpAndSettle();

    expect(find.text('Bill Estimate'), findsOneWidget);
    expect(find.text('Estimated bill — actual electricity bill may vary.'), findsWidgets);
    expect(find.text('PKR 9,102'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Save Estimate'), 200);
    await tester.tap(find.text('Save Estimate'));
    await tester.pumpAndSettle();
    expect(controller.history, hasLength(1));
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('switching to Urdu uses right-to-left layout', (tester) async {
    final controller = await _controller();
    await controller.updateSettings(controller.settings.copyWith(languageCode: 'ur'));
    await tester.pumpWidget(BillEstimatorApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('بجلی بل تخمینہ'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.text('بجلی بل تخمینہ')));
    expect(direction, TextDirection.rtl);
  });
}
