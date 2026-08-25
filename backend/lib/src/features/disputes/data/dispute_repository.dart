// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_category.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for booking-scoped disputes.
abstract class DisputeRepository {
  Future<Dispute?> findById(ObjectId id);

  Future<Dispute?> findByBookingId(ObjectId bookingId);

  Future<List<Dispute>> findByBookingIds(Iterable<ObjectId> ids);

  Future<Dispute> create(Dispute dispute);

  Future<DisputePage> adminPage({
    required int limit,
    DisputeStatus? status,
    DisputeCategory? category,
    ObjectId? bookingId,
    ObjectId? customerUserId,
    ObjectId? cleanerUserId,
    ObjectId? after,
  });

  Future<Dispute?> markUnderReview({
    required ObjectId id,
    required ObjectId adminUserId,
    required DateTime now,
  });

  Future<Dispute?> resolve({
    required ObjectId id,
    required ObjectId adminUserId,
    required String resolution,
    required DateTime now,
  });

  Future<Dispute?> close({
    required ObjectId id,
    required ObjectId actorUserId,
    required UserRole actorRole,
    required DateTime now,
  });

  Future<int> countActiveForUser(ObjectId userId);
}

/// MongoDB implementation of [DisputeRepository].
class MongoDisputeRepository implements DisputeRepository {
  MongoDisputeRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  factory MongoDisputeRepository.fromDb(Db db) {
    return MongoDisputeRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.disputes),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<Dispute?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<Dispute?> findByBookingId(ObjectId bookingId) {
    return _find(<String, dynamic>{'booking_id': bookingId});
  }

  @override
  Future<List<Dispute>> findByBookingIds(Iterable<ObjectId> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) {
      return const <Dispute>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'booking_id': <String, dynamic>{r'$in': unique},
      },
    );
    return documents.map(Dispute.fromDocument).toList();
  }

  @override
  Future<Dispute> create(Dispute dispute) async {
    final result = await _documents.insertOne(dispute.toDocument());
    if (result.isDuplicateKey) {
      throw const DisputeDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const DisputeWriteException();
    }
    return dispute;
  }

  @override
  Future<DisputePage> adminPage({
    required int limit,
    DisputeStatus? status,
    DisputeCategory? category,
    ObjectId? bookingId,
    ObjectId? customerUserId,
    ObjectId? cleanerUserId,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{};
    if (status != null) {
      selector['status'] = status.wireValue;
    }
    if (category != null) {
      selector['category'] = category.wireValue;
    }
    if (bookingId != null) {
      selector['booking_id'] = bookingId;
    }
    if (customerUserId != null) {
      selector['customer_user_id'] = customerUserId;
    }
    if (cleanerUserId != null) {
      selector['cleaner_user_id'] = cleanerUserId;
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
    final items = page.map(Dispute.fromDocument).toList();
    return DisputePage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  @override
  Future<Dispute?> markUnderReview({
    required ObjectId id,
    required ObjectId adminUserId,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': DisputeStatus.open.wireValue,
      },
      set: <String, dynamic>{
        'status': DisputeStatus.underReview.wireValue,
        'updated_at': utc,
      },
      history: DisputeHistoryEntry(
        fromStatus: DisputeStatus.open,
        toStatus: DisputeStatus.underReview,
        actorUserId: adminUserId,
        actorRole: UserRole.admin,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Dispute?> resolve({
    required ObjectId id,
    required ObjectId adminUserId,
    required String resolution,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final set = <String, dynamic>{
      'status': DisputeStatus.resolved.wireValue,
      'resolution': resolution,
      'resolved_by': adminUserId,
      'resolved_at': utc,
      'updated_at': utc,
    };
    final fromReview = await _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': DisputeStatus.underReview.wireValue,
      },
      set: set,
      history: DisputeHistoryEntry(
        fromStatus: DisputeStatus.underReview,
        toStatus: DisputeStatus.resolved,
        actorUserId: adminUserId,
        actorRole: UserRole.admin,
        note: resolution,
        createdAt: utc,
      ),
    );
    if (fromReview != null) {
      return fromReview;
    }
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': DisputeStatus.open.wireValue,
      },
      set: set,
      history: DisputeHistoryEntry(
        fromStatus: DisputeStatus.open,
        toStatus: DisputeStatus.resolved,
        actorUserId: adminUserId,
        actorRole: UserRole.admin,
        note: resolution,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Dispute?> close({
    required ObjectId id,
    required ObjectId actorUserId,
    required UserRole actorRole,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': DisputeStatus.resolved.wireValue,
      },
      set: <String, dynamic>{
        'status': DisputeStatus.closed.wireValue,
        'updated_at': utc,
      },
      history: DisputeHistoryEntry(
        fromStatus: DisputeStatus.resolved,
        toStatus: DisputeStatus.closed,
        actorUserId: actorUserId,
        actorRole: actorRole,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<int> countActiveForUser(ObjectId userId) async {
    final active = <String, dynamic>{
      'status': <String, dynamic>{
        r'$in': <String>[
          DisputeStatus.open.wireValue,
          DisputeStatus.underReview.wireValue,
          DisputeStatus.resolved.wireValue,
        ],
      },
    };
    final asCustomer = await _documents.count(<String, dynamic>{
      'customer_user_id': userId,
      ...active,
    });
    final asCleaner = await _documents.count(<String, dynamic>{
      'cleaner_user_id': userId,
      ...active,
    });
    return asCustomer + asCleaner;
  }

  Future<Dispute?> _transition({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> set,
    required DisputeHistoryEntry history,
  }) async {
    final result = await _documents.updateOne(
      selector: selector,
      update: <String, dynamic>{
        r'$set': set,
        r'$push': <String, dynamic>{'history': history.toDocument()},
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const DisputeWriteException();
    }
    if (!result.matched) {
      return null;
    }
    final id = selector['_id'];
    if (id is! ObjectId) {
      return null;
    }
    return findById(id);
  }

  Future<Dispute?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return Dispute.fromDocument(document);
  }
}
