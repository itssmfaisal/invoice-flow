class AccessRole {
  const AccessRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.users,
  });

  final String id;
  final String name;
  final String description;
  final int permissions;
  final int users;
}

class TeamMember {
  const TeamMember({required this.name, required this.email, required this.roleName, this.active = true});

  final String name;
  final String email;
  final String roleName;
  final bool active;
}

class Integration {
  const Integration({required this.id, required this.name, required this.description, required this.connected});

  final String id;
  final String name;
  final String description;
  final bool connected;

  Integration copyWith({bool? connected}) =>
      Integration(id: id, name: name, description: description, connected: connected ?? this.connected);
}

class NotificationItem {
  const NotificationItem({required this.title, required this.body, required this.time, this.read = false});

  final String title;
  final String body;
  final DateTime time;
  final bool read;

  NotificationItem markRead() => NotificationItem(title: title, body: body, time: time, read: true);
}

class AuditEvent {
  const AuditEvent({required this.action, required this.actor, required this.time});

  final String action;
  final String actor;
  final DateTime time;
}

class ComplianceInfo {
  const ComplianceInfo({
    required this.licenseType,
    required this.licenseNumber,
    required this.regulator,
    required this.licenseValidUntil,
    required this.lastAmlScreening,
  });

  final String licenseType;
  final String licenseNumber;
  final String regulator;
  final DateTime licenseValidUntil;
  final DateTime lastAmlScreening;

  ComplianceInfo copyWith({DateTime? lastAmlScreening}) => ComplianceInfo(
        licenseType: licenseType,
        licenseNumber: licenseNumber,
        regulator: regulator,
        licenseValidUntil: licenseValidUntil,
        lastAmlScreening: lastAmlScreening ?? this.lastAmlScreening,
      );
}

class WorkspaceSettings {
  const WorkspaceSettings({
    required this.roles,
    required this.members,
    required this.integrations,
    required this.notificationPrefs,
    required this.auditLog,
    required this.compliance,
  });

  final List<AccessRole> roles;
  final List<TeamMember> members;
  final List<Integration> integrations;
  final Map<String, bool> notificationPrefs;
  final List<AuditEvent> auditLog;
  final ComplianceInfo compliance;
}
