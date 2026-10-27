import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'compliance_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'suppliers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user!;
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return ListView(
      padding: pagePadding,
      children: [
        const ScreenHeader(title: 'More'),
        AppCard(
          color: AppColors.lavenderLight,
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.purple,
              child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(user.email, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 6),
                Pill(label: '${user.role.label} · ${user.organizationName}', color: AppColors.purple, icon: roleIcon(user.role)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (user.role != UserRole.supplier)
          _MenuTile(
            icon: Icons.groups_outlined,
            title: 'Suppliers',
            subtitle: 'Supplier network, KYC status and volumes',
            onTap: () => open(const SuppliersScreen()),
          ),
        _MenuTile(
          icon: Icons.bar_chart_rounded,
          title: 'Reports',
          subtitle: 'Settlements, reconciliation and CSV export',
          onTap: () => open(const ReportsScreen()),
        ),
        _MenuTile(
          icon: Icons.verified_user_outlined,
          title: 'Compliance',
          subtitle: 'KYC / AML, licensing and audit',
          onTap: () => open(const ComplianceScreen()),
        ),
        _MenuTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: state.unreadNotifications == 0 ? 'All caught up' : '${state.unreadNotifications} unread',
          onTap: () => open(const NotificationsScreen()),
        ),
        _MenuTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Users, roles, integrations, security',
          onTap: () => open(const SettingsScreen()),
        ),
        const SizedBox(height: 8),
        _MenuTile(
          icon: Icons.logout,
          title: 'Sign out',
          color: AppColors.red,
          onTap: () async {
            final ok = await confirmDialog(context,
                title: 'Sign out?', message: 'You can sign in again with any role.', confirmLabel: 'Sign out');
            if (ok) state.signOut();
          },
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('InvoiceFlow 1.0.0 · demo data', style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.subtitle, required this.onTap, this.color});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.purple),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 12)),
          trailing: color == null ? const Icon(Icons.chevron_right) : null,
        ),
      ),
    );
  }
}
