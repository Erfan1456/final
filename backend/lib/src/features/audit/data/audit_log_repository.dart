// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_log.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Append-only persistence for administrative audit records.
abstract class AuditLogRepository {
  Future<AuditLog> append(AuditLog log);

  Future<AuditLog?> findById(ObjectId id);

  Future<AuditLogPage> listPage({
    required int limit,
    ObjectId? actorUserId,
    AuditAction? action,
    String? targetType,
    ObjectId? targetId,
    DateTime? from,
    DateTime? to,
    ObjectId? after,
  });
}

/// MongoDB implementation of [AuditLogRepository]. No update or delete.
class MongoAuditLogRepository implements AuditLogRepository {
  MongoAuditLogRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  factory MongoAuditLogRepository.fromDb(Db db) {
    return MongoAuditLogRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.auditLogs),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<AuditLog> append(AuditLog log) async {
    final result = await _documents.insertOne(log.toDocument());
    if (!result.isSuccess) {
      throw const AuditLogWriteException();
    }
    return log;
  }

  @override
  Future<AuditLog?> findById(ObjectId id) async {
    final document = await _documents.findOne(<String, dynamic>{'_id': id});
    if (document == null) {
      return null;
    }
    return AuditLog.fromDocument(document);
  }

  @override
  Future<AuditLogPage> listPage({
    required int limit,
    ObjectId? actorUserId,
    AuditAction? action,
    String? targetType,
    ObjectId? targetId,
    DateTime? from,
    DateTime? to,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{};
    if (actorUserId != null) {
      selector['actor_user_id'] = actorUserId;
    }
    if (action != null) {
      selector['action'] = action.wireValue;
    }
    if (targetType != null) {
      selector['target_type'] = targetType;
    }
    if (targetId != null) {
      selector['target_id'] = targetId;
    }
    if (from != null || to != null) {
      selector['created_at'] = <String, dynamic>{
        if (from != null) r'$gte': from.toUtc(),
        if (to != null) r'$lte': to.toUtc(),
      };
    }
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$lt': after};
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'_id': -1},
      limit: limit + 1,
    );
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;
    final items = page.map(AuditLog.fromDocument).toList();
    return AuditLogPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }
}
