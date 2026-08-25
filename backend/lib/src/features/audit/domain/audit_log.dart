// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One append-only administrative audit record.
class AuditLog {
  /// Creates an audit log. [id] is the MongoDB `_id`.
  const AuditLog({
    required this.id,
    required this.actorUserId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.reason,
    this.metadata = const <String, Object?>{},
  });

  /// Parses a MongoDB `audit_logs` document.
  factory AuditLog.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => AuditLogDocumentException(message);
    return AuditLog(
      id: DocumentFields.requireObjectId(document, '_id', error),
      actorUserId: DocumentFields.requireObjectId(
        document,
        'actor_user_id',
        error,
      ),
      actorRole: UserRole.fromWire(
        DocumentFields.requireString(document, 'actor_role', error),
      ),
      action: AuditAction.fromWire(
        DocumentFields.requireString(document, 'action', error),
      ),
      targetType: DocumentFields.requireString(document, 'target_type', error),
      targetId: DocumentFields.requireObjectId(document, 'target_id', error),
      reason: DocumentFields.optionalString(document, 'reason', error),
      metadata: _readMetadata(document['metadata'], error),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
    );
  }

  final ObjectId id;
  final ObjectId actorUserId;
  final UserRole actorRole;
  final AuditAction action;
  final String targetType;
  final ObjectId targetId;
  final String? reason;
  final Map<String, Object?> metadata;
  final DateTime createdAt;

  /// MongoDB document. Metadata is restricted to safe scalars.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'actor_user_id': actorUserId,
      'actor_role': actorRole.wireValue,
      'action': action.wireValue,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'metadata': Map<String, Object?>.from(metadata),
      'created_at': createdAt.toUtc(),
    };
  }

  /// Admin-safe JSON. No passwords, tokens, or session data.
  Map<String, Object?> toAdminJson() {
    return <String, Object?>{
      'id': id.oid,
      'actor_user_id': actorUserId.oid,
      'actor_role': actorRole.wireValue,
      'action': action.wireValue,
      'target_type': targetType,
      'target_id': targetId.oid,
      'reason': reason,
      'metadata': Map<String, Object?>.from(metadata),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, Object?> _readMetadata(
    Object? raw,
    Exception Function(String message) onError,
  ) {
    if (raw == null) {
      return const <String, Object?>{};
    }
    if (raw is! Map) {
      throw onError('metadata must be Map or null.');
    }
    return sanitizeMetadata(Map<Object?, Object?>.from(raw));
  }

  /// Keeps only string/int/bool/null scalars. Nested values and secret keys
  /// are dropped.
  static Map<String, Object?> sanitizeMetadata(Map<Object?, Object?> raw) {
    const blocked = <String>{
      'password',
      'password_hash',
      'jwt',
      'access_token',
      'refresh_token',
      'idempotency_key',
      'request_fingerprint',
      'webhook_signature',
      'webhook_secret',
      'mongo_uri',
      'mongodb_uri',
    };
    final sanitized = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String || key.isEmpty) {
        continue;
      }
      if (blocked.contains(key.toLowerCase())) {
        continue;
      }
      final value = entry.value;
      if (value == null || value is String || value is bool || value is int) {
        sanitized[key] = value;
      }
    }
    return sanitized;
  }
}

/// One keyset page of audit logs.
class AuditLogPage {
  const AuditLogPage({required this.items, required this.nextCursor});

  final List<AuditLog> items;
  final String? nextCursor;
}
