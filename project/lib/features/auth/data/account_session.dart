/// Safe listed session metadata from GET /api/v1/account/sessions.
class AccountSession {
  /// Creates a session summary.
  const AccountSession({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.lastRotatedAt,
    required this.isCurrent,
  });

  /// Parses one session object. Unknown fields are ignored.
  factory AccountSession.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final createdAt = json['created_at'];
    final expiresAt = json['expires_at'];
    final lastRotatedAt = json['last_rotated_at'];
    final isCurrent = json['is_current'];
    if (id is! String ||
        id.isEmpty ||
        createdAt is! String ||
        expiresAt is! String ||
        lastRotatedAt is! String ||
        isCurrent is! bool) {
      throw const FormatException('Session JSON is missing required fields.');
    }
    return AccountSession(
      id: id,
      createdAt: DateTime.parse(createdAt).toUtc(),
      expiresAt: DateTime.parse(expiresAt).toUtc(),
      lastRotatedAt: DateTime.parse(lastRotatedAt).toUtc(),
      isCurrent: isCurrent,
    );
  }

  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastRotatedAt;
  final bool isCurrent;
}
