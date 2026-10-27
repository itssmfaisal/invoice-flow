import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'analytics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'financing/financing_screen.dart';
import 'invoices_screen.dart';
import 'more_screen.dart';

/// Bottom-tab layout used after sign-in. Replaces the desktop sidebar.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final financingLabel = switch (state.role) {
      UserRole.buyer => 'Early Pay',
      UserRole.supplier => 'Financing',
      UserRole.lender => 'Funding',
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: state.tabIndex,
          children: const [
            DashboardScreen(),
            InvoicesScreen(),
            FinancingScreen(),
            AnalyticsScreen(),
            MoreScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.setTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lavender,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Dashboard'),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Invoices'),
          NavigationDestination(
              icon: const Icon(Icons.payments_outlined), selectedIcon: const Icon(Icons.payments), label: financingLabel),
          const NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Analytics'),
          const NavigationDestination(icon: Icon(Icons.menu_rounded), label: 'More'),
        ],
      ),
    );
  }
}
