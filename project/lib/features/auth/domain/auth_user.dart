/// Safe current-account representation from GET /api/v1/account/me.
class AuthUser {
  /// Creates a user. Backend IDs remain strings.
  const AuthUser({
    required this.id,
    required this.role,
    required this.email,
    required this.accountStatus,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses the safe public user object. Unknown extra fields are ignored.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['role'];
    final email = json['email'];
    final accountStatus = json['account_status'];
    final emailVerified = json['email_verified'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    if (id is! String ||
        id.isEmpty ||
        role is! String ||
        role.isEmpty ||
        email is! String ||
        email.isEmpty ||
        accountStatus is! String ||
        accountStatus.isEmpty ||
        emailVerified is! bool ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException('Account JSON is missing required fields.');
    }
    return AuthUser(
      id: id,
      role: role,
      email: email,
      accountStatus: accountStatus,
      emailVerified: emailVerified,
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  final String id;
  final String role;
  final String email;
  final String accountStatus;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  String toString() =>
      'AuthUser(id: $id, role: $role, accountStatus: $accountStatus)';
}
