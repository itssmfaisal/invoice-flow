import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.purple,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.purple,
            labelStyle: TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Roles'),
              Tab(text: 'Integrations'),
              Tab(text: 'Notifications'),
              Tab(text: 'Security'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _UsersTab(),
          _RolesTab(),
          _IntegrationsTab(),
          _NotificationsTab(),
          _SecurityTab(),
        ]),
      ),
    );
  }
}

const _tabPadding = EdgeInsets.fromLTRB(16, 16, 16, 24);

// -----------------------------------------------------------------------------
// Users
// -----------------------------------------------------------------------------

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  Future<void> _invite(BuildContext context) async {
    final state = AppScope.read(context);
    final name = TextEditingController();
    final email = TextEditingController();
    var roleName = state.settings!.roles.first.name;
    final member = await showDialog<TeamMember>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite user'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: roleName,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final r in state.settings!.roles) DropdownMenuItem(value: r.name, child: Text(r.name)),
              ],
              onChanged: (v) => setDialogState(() => roleName = v ?? roleName),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () {
                if (name.text.trim().isEmpty || !email.text.contains('@')) return;
                Navigator.pop(context, TeamMember(name: name.text.trim(), email: email.text.trim(), roleName: roleName));
              },
              child: const Text('Send invite'),
            ),
          ],
        ),
      ),
    );
    if (member == null) return;
    await state.inviteMember(member);
    if (context.mounted) showSnack(context, 'Invitation sent to ${member.email}');
  }

  @override
  Widget build(BuildContext context) {
    final members = AppScope.of(context).settings!.members;
    return ListView(
      padding: _tabPadding,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => _invite(context),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Invite user'),
          ),
        ),
        const SizedBox(height: 12),
        for (final m in members)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.lavenderLight,
                  child: Text(m.name[0], style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
                ),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${m.email}\n${m.roleName}', style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
                trailing: Pill(
                  label: m.active ? 'Active' : 'Inactive',
                  color: m.active ? AppColors.green : AppColors.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Roles (matches the Settings > Roles table in the design)
// -----------------------------------------------------------------------------

class _RolesTab extends StatelessWidget {
  const _RolesTab();

  Future<void> _edit(BuildContext context, [AccessRole? role]) async {
    final state = AppScope.read(context);
    final name = TextEditingController(text: role?.name ?? '');
    final description = TextEditingController(text: role?.description ?? '');
    var permissions = (role?.permissions ?? 6).toDouble();
    final saved = await showDialog<AccessRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(role == null ? 'New role' : 'Edit role'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Role name')),
            const SizedBox(height: 10),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 14),
            Text('Permissions: ${permissions.round()}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(
              value: permissions,
              min: 1,
              max: 24,
              divisions: 23,
              onChanged: (v) => setDialogState(() => permissions = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  AccessRole(
                    id: role?.id ?? state.newId('role'),
                    name: name.text.trim(),
                    description: description.text.trim(),
                    permissions: permissions.round(),
                    users: role?.users ?? 0,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != null) await state.saveRole(saved);
  }

  Future<void> _delete(BuildContext context, AccessRole role) async {
    final state = AppScope.read(context);
    final ok = await confirmDialog(context,
        title: 'Delete ${role.name}?',
        message: '${role.users} users have this role. They will lose these permissions.',
        confirmLabel: 'Delete',
        destructive: true);
    if (ok) await state.deleteRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final roles = AppScope.of(context).settings!.roles;
    return ListView(
      padding: _tabPadding,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Role'),
          ),
        ),
        const SizedBox(height: 12),
        for (final role in roles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(role.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(role.description, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: [
                      Pill(label: '${role.permissions} permissions', color: AppColors.purple, icon: Icons.key),
                      Pill(label: '${role.users} users', color: AppColors.blue, icon: Icons.person_outline),
                    ]),
                  ]),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _edit(context, role),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.amber),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _delete(context, role),
                  icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Integrations (AP / procurement / ERP / bank)
// -----------------------------------------------------------------------------

class _IntegrationsTab extends StatelessWidget {
  const _IntegrationsTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: _tabPadding,
      children: [
        const NoticeBox(
          icon: Icons.hub_outlined,
          color: AppColors.blue,
          title: 'Embed InvoiceFlow in your AP / procurement workflow',
          lines: ['Approved invoices sync in automatically and become eligible for early payment.'],
        ),
        const SizedBox(height: 12),
        for (final integration in state.settings!.integrations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                value: integration.connected,
                onChanged: (_) => state.toggleIntegration(integration),
                title: Text(integration.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(integration.description, style: const TextStyle(fontSize: 12)),
                secondary: Icon(
                  integration.connected ? Icons.link : Icons.link_off,
                  color: integration.connected ? AppColors.green : AppColors.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Notifications
// -----------------------------------------------------------------------------

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final prefs = state.settings!.notificationPrefs;
    return ListView(
      padding: _tabPadding,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final entry in prefs.entries)
              SwitchListTile(
                value: entry.value,
                onChanged: (v) => state.setNotificationPref(entry.key, v),
                title: Text(entry.key, style: const TextStyle(fontSize: 14)),
              ),
          ]),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Security
// -----------------------------------------------------------------------------

class _SecurityTab extends StatefulWidget {
  const _SecurityTab();

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  bool _twoFactor = true;
  bool _biometric = false;
  int _timeoutMinutes = 15;

  @override
  Widget build(BuildContext context) {
    final audit = AppScope.of(context).settings!.auditLog;
    return ListView(
      padding: _tabPadding,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            SwitchListTile(
              value: _twoFactor,
              onChanged: (v) => setState(() => _twoFactor = v),
              title: const Text('Two-factor authentication'),
              subtitle: const Text('Required for approvals and payments', style: TextStyle(fontSize: 12)),
            ),
            SwitchListTile(
              value: _biometric,
              onChanged: (v) => setState(() => _biometric = v),
              title: const Text('Biometric login'),
            ),
            ListTile(
              title: const Text('Session timeout'),
              trailing: DropdownButton<int>(
                value: _timeoutMinutes,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 min')),
                  DropdownMenuItem(value: 15, child: Text('15 min')),
                  DropdownMenuItem(value: 30, child: Text('30 min')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                ],
                onChanged: (v) => setState(() => _timeoutMinutes = v ?? _timeoutMinutes),
              ),
            ),
          ]),
        ),
        const SectionHeader(title: 'Audit log'),
        for (final event in audit)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: AppColors.purple),
            title: Text(event.action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${event.actor} · ${Fmt.relative(event.time)}', style: const TextStyle(fontSize: 11)),
          ),
      ],
    );
  }
}
