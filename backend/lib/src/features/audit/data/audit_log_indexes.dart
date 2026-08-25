// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

const String auditLogsActorIdDescIndexName = 'audit_logs_actor_id_desc';
const String auditLogsActionIdDescIndexName = 'audit_logs_action_id_desc';
const String auditLogsTargetIdDescIndexName = 'audit_logs_target_id_desc';
const String auditLogsCreatedAtIndexName = 'audit_logs_created_at';

const String auditLogsActorUserIdField = 'actor_user_id';
const String auditLogsActionField = 'action';
const String auditLogsTargetTypeField = 'target_type';
const String auditLogsTargetIdField = 'target_id';
const String auditLogsCreatedAtField = 'created_at';

typedef EnsureAuditIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `audit_logs` indexes for admin listing filters.
Future<void> ensureAuditLogIndexes({
  required EnsureAuditIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.auditLogs,
    keys: const <String, dynamic>{auditLogsActorUserIdField: 1, '_id': -1},
    unique: false,
    name: auditLogsActorIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.auditLogs,
    keys: const <String, dynamic>{auditLogsActionField: 1, '_id': -1},
    unique: false,
    name: auditLogsActionIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.auditLogs,
    keys: const <String, dynamic>{
      auditLogsTargetTypeField: 1,
      auditLogsTargetIdField: 1,
      '_id': -1,
    },
    unique: false,
    name: auditLogsTargetIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.auditLogs,
    keys: const <String, dynamic>{auditLogsCreatedAtField: -1, '_id': -1},
    unique: false,
    name: auditLogsCreatedAtIndexName,
  );
}

/// Ensures audit log indexes on [db].
Future<void> ensureAuditLogIndexesOnDb(Db db) {
  return ensureAuditLogIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
        }) async {
          final collection = db.collection(collectionName);
          try {
            await collection.createIndex(
              keys: keys,
              unique: unique,
              name: name,
            );
          } catch (_) {
            final indexes = await collection.getIndexes();
            final exists = indexes.any((index) => index['name'] == name);
            if (!exists) {
              rethrow;
            }
          }
        },
  );
}
