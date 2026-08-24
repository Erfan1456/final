import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persisted user account identity record.
class UserAccount {
  /// Creates a persisted account. [id] is the MongoDB `_id`.
  const UserAccount({
    required this.id,
    required this.role,
    required this.email,
    required this.emailNormalized,
    required this.passwordHash,
    required this.accountStatus,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a MongoDB `users` document. Missing or wrong critical types fail.
  factory UserAccount.fromDocument(Map<String, dynamic> document) {
    return UserAccount(
      id: _requireObjectId(document, '_id'),
      role: UserRole.fromWire(_requireString(document, 'role')),
      email: _requireString(document, 'email'),
      emailNormalized: _requireString(document, 'email_normalized'),
      passwordHash: _requireString(document, 'password_hash'),
      accountStatus: AccountStatus.fromWire(
        _requireString(document, 'account_status'),
      ),
      emailVerified: _requireBool(document, 'email_verified'),
      createdAt: _requireUtcDateTime(document, 'created_at'),
      updatedAt: _requireUtcDateTime(document, 'updated_at'),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Account role.
  final UserRole role;

  /// User-facing email retained for communication/display.
  final String email;

  /// Trimmed lowercase email used for lookup and uniqueness.
  final String emailNormalized;

  /// Stored password hash. Never expose this in public JSON or logs.
  final String passwordHash;

  /// Account lifecycle status. Not cleaner approval.
  final AccountStatus accountStatus;

  /// Whether the email address has been verified.
  final bool emailVerified;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation, including the password hash.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'role': role.wireValue,
      'email': email,
      'email_normalized': emailNormalized,
      'password_hash': passwordHash,
      'account_status': accountStatus.wireValue,
      'email_verified': emailVerified,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Safe public representation. Never includes password or normalized email.
  Map<String, Object> toPublicJson() {
    return <String, Object>{
      'id': id.oid,
      'role': role.wireValue,
      'email': email,
      'accountStatus': accountStatus.wireValue,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() =>
      'UserAccount(id: ${id.oid}, role: ${role.wireValue}, '
      'accountStatus: ${accountStatus.wireValue})';

  static ObjectId _requireObjectId(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is ObjectId) {
      return value;
    }
    throw UserAccountDocumentException('$field must be ObjectId.');
  }

  static String _requireString(Map<String, dynamic> document, String field) {
    final value = document[field];
    if (value is String) {
      return value;
    }
    throw UserAccountDocumentException('$field must be String.');
  }

  static bool _requireBool(Map<String, dynamic> document, String field) {
    final value = document[field];
    if (value is bool) {
      return value;
    }
    throw UserAccountDocumentException('$field must be bool.');
  }

  static DateTime _requireUtcDateTime(
    Map<String, dynamic> document,
    String field,
  ) {
    final value = document[field];
    if (value is DateTime) {
      return value.toUtc();
    }
    throw UserAccountDocumentException('$field must be DateTime.');
  }
}
