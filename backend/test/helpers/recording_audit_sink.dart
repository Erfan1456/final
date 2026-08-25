import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Test sink that records audit appends and can fail on demand.
class RecordingAuditSink implements AuditSink {
  final List<Map<String, Object?>> appended = <Map<String, Object?>>[];

  bool throwOnAppend = false;

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
    if (throwOnAppend) {
      throw StateError('audit write failed');
    }
    appended.add(<String, Object?>{
      'actor_user_id': actorUserId,
      'actor_role': actorRole,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'metadata': metadata,
    });
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
    } catch (_) {}
  }
}
