enum UserRole {
  buyer('Buyer', 'Buyer AP / procurement'),
  supplier('Supplier', 'Supplier finance team'),
  lender('Lender', 'Funding partner');

  const UserRole(this.label, this.description);
  final String label;
  final String description;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.organizationId,
    required this.organizationName,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Buyer id, supplier id or funding-partner id, depending on [role].
  final String organizationId;
  final String organizationName;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
