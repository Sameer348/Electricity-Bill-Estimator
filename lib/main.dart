import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/storage_service.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final controller = AppController(storage: await PrefsStorageService.create());
  await controller.load();
  runApp(BillEstimatorApp(controller: controller));
}
