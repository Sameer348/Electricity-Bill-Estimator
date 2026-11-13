import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// Exposes [AppController] to the widget tree and rebuilds dependents when it
/// notifies. Avoids pulling in a state-management package for a small app.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }

  /// Access without subscribing to rebuilds (for callbacks).
  static AppController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}

extension AppScopeContext on BuildContext {
  AppController get app => AppScope.of(this);
  AppController get appRead => AppScope.read(this);
}
