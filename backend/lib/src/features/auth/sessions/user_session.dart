import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persisted logical login/device session.
class UserSession {
  /// Creates a persisted session. [id] is the MongoDB `_id`.
  const UserSession({
    required this.id,
    required this.userId,
    required this.refreshTokenHash,
    required this.usedRefreshTokenHashes,
    required this.expiresAt,
    required this.createdAt,
    required this.lastRotatedAt,
    this.revokedAt,
  });

  /// Parses a MongoDB `user_sessions` document.
  factory UserSession.fromDocument(Map<String, dynamic> document) {
    return UserSession(
      id: _requireObjectId(document, '_id'),
      userId: _requireObjectId(document, 'user_id'),
      refreshTokenHash: _requireString(document, 'refresh_token_hash'),
      usedRefreshTokenHashes: _requireStringList(
        document,
        'used_refresh_token_hashes',
      ),
      expiresAt: _requireUtcDateTime(document, 'expires_at'),
      revokedAt: _optionalUtcDateTime(document, 'revoked_at'),
      createdAt: _requireUtcDateTime(document, 'created_at'),
      lastRotatedAt: _requireUtcDateTime(document, 'last_rotated_at'),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Owning user `_id`.
  final ObjectId userId;

  /// Current refresh-token SHA-256 hash. Never log or expose publicly.
  final String refreshTokenHash;

  /// Previously consumed refresh-token hashes for replay detection.
  final List<String> usedRefreshTokenHashes;

  /// Absolute UTC expiration. Rotation does not extend this.
  final DateTime expiresAt;

  /// UTC revocation time, or `null` when active.
  final DateTime? revokedAt;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC time of the last successful rotation (or creation).
  final DateTime lastRotatedAt;

  /// Whether [revokedAt] is set.
  bool get isRevoked => revokedAt != null;

  /// Whether the session is past [expiresAt] at [now].
  bool isExpiredAt(DateTime now) => !expiresAt.toUtc().isAfter(now.toUtc());

  /// MongoDB document representation, including token hashes.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'refresh_token_hash': refreshTokenHash,
      'used_refresh_token_hashes': List<String>.from(usedRefreshTokenHashes),
      'expires_at': expiresAt.toUtc(),
      'revoked_at': revokedAt?.toUtc(),
      'created_at': createdAt.toUtc(),
      'last_rotated_at': lastRotatedAt.toUtc(),
    };
  }

  @override
  String toString() =>
      'UserSession(id: ${id.oid}, userId: ${userId.oid}, '
      'revoked: $isRevoked)';

  static ObjectId _requireObjectId(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is ObjectId) {
      return value;
    }
    throw UserSessionDocumentException('$field must be ObjectId.');
  }

  static String _requireString(Map<String, dynamic> document, String field) {
    final value = document[field];
    if (value is String) {
      return value;
    }
    throw UserSessionDocumentException('$field must be String.');
  }

  static List<String> _requireStringList(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is List) {
      final hashes = <String>[];
      for (final item in value) {
        if (item is! String) {
          throw UserSessionDocumentException('$field must be List<String>.');
        }
        hashes.add(item);
      }
      return hashes;
    }
    throw UserSessionDocumentException('$field must be List<String>.');
  }

  static DateTime _requireUtcDateTime(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is DateTime) {
      return value.toUtc();
    }
    throw UserSessionDocumentException('$field must be DateTime.');
  }

  static DateTime? _optionalUtcDateTime(
    Map<String, dynamic> document,
    String field,
  ) {
    if (!document.containsKey(field) || document[field] == null) {
      return null;
    }
    return _requireUtcDateTime(document, field);
  }
}
