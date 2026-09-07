import 'package:flutter/material.dart';

import 'package:track_me/screens/budgets/budgets_screen.dart';
import 'package:track_me/screens/dashboard/dashboard_screen.dart';
import 'package:track_me/screens/insights/insights_screen.dart';
import 'package:track_me/screens/settings/settings_screen.dart';
import 'package:track_me/screens/transactions/quick_add_sheet.dart';
import 'package:track_me/screens/transactions/transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const BudgetsScreen(),
      const TransactionsScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: _index == 4 ? null : const _QuickAddFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.swap_vert), selectedIcon: Icon(Icons.swap_vert), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _QuickAddFab extends StatelessWidget {
  const _QuickAddFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const QuickAddSheet(),
      ),
      child: const Icon(Icons.add, size: 28),
    );
  }
}