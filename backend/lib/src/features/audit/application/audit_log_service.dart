// ignore_for_file: public_member_api_docs
import 'dart:developer' as developer;

import 'package:home_cleaning_marketplace_api/src/features/audit/data/audit_log_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_log.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Narrow sink used by admin services. Implementations must not roll back
/// the caller's primary action.
abstract class AuditSink {
  Future<void> append({
    required ObjectId actorUserId,
    required UserRole actorRole,
    required AuditAction action,
    required String targetType,
    required ObjectId targetId,
    String? reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  });

  Future<void> appendBestEffort({
    required ObjectId actorUserId,
    required UserRole actorRole,
    required AuditAction action,
    required String targetType,
    required ObjectId targetId,
    String? reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  });
}

/// No-op sink used when audit is not wired.
class NoOpAuditSink implements AuditSink {
  const NoOpAuditSink();

  @override
  Future<void> append({
    required ObjectId actorUserId,
    required UserRole actorRole,
    required AuditAction action,
    required String targetType,
    required ObjectId targetId,
    String? reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {}

  @override
  Future<void> appendBestEffort({
    required ObjectId actorUserId,
    required UserRole actorRole,
    required AuditAction action,
    required String targetType,
    required ObjectId targetId,
    String? reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {}
}

/// HTTP-independent audit append and admin listing.
class AuditLogService implements AuditSink {
  AuditLogService({
    required AuditLogRepository logs,
    DateTime Function()? clock,
  }) : _logs = logs,
       _clock = clock ?? DateTime.now;

  final AuditLogRepository _logs;
  final DateTime Function() _clock;

  @override
  Future<void> append({
    required ObjectId actorUserId,
    required UserRole actorRole,
    required AuditAction action,
    required String targetType,
    required ObjectId targetId,
    String? reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    await _logs.append(
      AuditLog(
        id: ObjectId(),
        actorUserId: actorUserId,
        actorRole: actorRole,
        action: action,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        metadata: AuditLog.sanitizeMetadata(metadata),
        createdAt: _clock().toUtc(),
      ),
    );
  }

  @override
  Future<void> appendBestEffort({
    required ObjectId actorUserId,
    required UserRole actorRole,
    required AuditAction action,
    required String targetType,
    required ObjectId targetId,
    String? reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    try {
      await append(
        actorUserId: actorUserId,
        actorRole: actorRole,
        action: action,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        metadata: metadata,
      );
    } catch (_) {
      developer.log('audit_log_append_failed', name: 'audit');
    }
  }

  Future<Map<String, Object?>> list({
    Object? actorUserId,
    Object? action,
    Object? targetType,
    Object? targetId,
    Object? from,
    Object? to,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _logs.listPage(
      limit: AuditValidation.requireLimit(limitRaw),
      actorUserId: AuditValidation.optionalObjectId(actorUserId),
      action: AuditValidation.optionalAction(action),
      targetType: AuditValidation.optionalTargetType(targetType),
      targetId: AuditValidation.optionalObjectId(targetId),
      from: AuditValidation.optionalUtcDateTime(from),
      to: AuditValidation.optionalUtcDateTime(to),
      after: AuditValidation.optionalObjectId(after),
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toAdminJson()],
      'next_cursor': page.nextCursor,
    };
  }

  Future<Map<String, Object?>> detail(ObjectId auditLogId) async {
    final log = await _logs.findById(auditLogId);
    if (log == null) {
      throw const AuditLogNotFoundException();
    }
    return log.toAdminJson();
  }
}
