import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/formatters.dart';
import 'appliance_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

/// Bottom-navigation container for the three main tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _unitsController = TextEditingController();

  @override
  void dispose() {
    _unitsController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _index = index);
  }

  void _useApplianceUnits(double units) {
    _unitsController.text = Fmt.units(units).replaceAll(',', '');
    _goTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(unitsController: _unitsController, onViewAllHistory: () => _goTo(2)),
            ApplianceScreen(onUseUnits: _useApplianceUnits),
            const HistoryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt),
            label: context.tr('navHome'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: context.tr('navAppliances'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: context.tr('navHistory'),
          ),
        ],
      ),
    );
  }
}
