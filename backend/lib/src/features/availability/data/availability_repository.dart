import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for open availability slots.
abstract class AvailabilityRepository {
  /// Counts slots owned by [cleanerUserId] with `start_at` after [now].
  Future<int> countFutureForCleaner({
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Lists owned slots whose `start_at` is in [[from], [to]], sorted ascending.
  Future<List<AvailabilitySlot>> listForCleaner({
    required ObjectId cleanerUserId,
    required DateTime from,
    required DateTime to,
    ObjectId? serviceId,
  });

  /// Finds a slot by [id], regardless of owner or start time.
  Future<AvailabilitySlot?> findById(ObjectId id);

  /// Finds an owned future slot by [id] and [cleanerUserId].
  Future<AvailabilitySlot?> findOwnedFutureById({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Finds one overlapping slot, optionally excluding [excludeId].
  Future<AvailabilitySlot?> findOverlap({
    required ObjectId cleanerUserId,
    required DateTime startAt,
    required DateTime endAt,
    ObjectId? excludeId,
  });

  /// Inserts [slot]. Duplicate `cleaner_user_id`+`start_at` is reported.
  Future<AvailabilitySlot> create(AvailabilitySlot slot);

  /// Updates an owned future slot using id, owner, and a future start.
  Future<AvailabilitySlot?> updateOwnedFuture({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
    required ObjectId serviceId,
    required DateTime startAt,
    required DateTime endAt,
  });

  /// Deletes an owned future slot using id, owner, and a future start.
  Future<bool> deleteOwnedFuture({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Lists future slots for one cleaner and service, `start_at` ascending.
  Future<List<AvailabilitySlot>> listFutureForCleanerAndService({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  });

  /// Lists overlapping slots for the given cleaners, service, and window.
  Future<List<AvailabilitySlot>> listOverlappingForCleaners({
    required Iterable<ObjectId> cleanerUserIds,
    required ObjectId serviceId,
    required DateTime from,
    required DateTime to,
  });

  /// Lists future slots for the given cleaners and service.
  Future<List<AvailabilitySlot>> listFutureForCleanersAndService({
    required Iterable<ObjectId> cleanerUserIds,
    required ObjectId serviceId,
    required DateTime now,
  });
}

/// MongoDB implementation of [AvailabilityRepository].
class MongoAvailabilityRepository implements AvailabilityRepository {
  /// Creates a repository over [documents].
  MongoAvailabilityRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the availability_slots collection on [db].
  factory MongoAvailabilityRepository.fromDb(Db db) {
    return MongoAvailabilityRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.availabilitySlots),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<int> countFutureForCleaner({
    required ObjectId cleanerUserId,
    required DateTime now,
  }) {
    return _documents.count(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'start_at': <String, dynamic>{r'$gt': now.toUtc()},
    });
  }

  @override
  Future<List<AvailabilitySlot>> listForCleaner({
    required ObjectId cleanerUserId,
    required DateTime from,
    required DateTime to,
    ObjectId? serviceId,
  }) async {
    final selector = <String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'start_at': <String, dynamic>{
        r'$gte': from.toUtc(),
        r'$lte': to.toUtc(),
      },
    };
    if (serviceId != null) {
      selector['service_id'] = serviceId;
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'start_at': 1},
    );
    return documents.map(AvailabilitySlot.fromDocument).toList();
  }

  @override
  Future<AvailabilitySlot?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<AvailabilitySlot?> findOwnedFutureById({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  }) {
    return _find(<String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
      'start_at': <String, dynamic>{r'$gt': now.toUtc()},
    });
  }

  @override
  Future<AvailabilitySlot?> findOverlap({
    required ObjectId cleanerUserId,
    required DateTime startAt,
    required DateTime endAt,
    ObjectId? excludeId,
  }) {
    final selector = <String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'start_at': <String, dynamic>{r'$lt': endAt.toUtc()},
      'end_at': <String, dynamic>{r'$gt': startAt.toUtc()},
    };
    if (excludeId != null) {
      selector['_id'] = <String, dynamic>{r'$ne': excludeId};
    }
    return _find(selector);
  }

  @override
  Future<AvailabilitySlot> create(AvailabilitySlot slot) async {
    final result = await _documents.insertOne(slot.toDocument());
    if (result.isDuplicateKey) {
      throw const AvailabilityOverlapException();
    }
    if (!result.isSuccess) {
      throw const AvailabilityWriteException();
    }
    return slot;
  }

  @override
  Future<AvailabilitySlot?> updateOwnedFuture({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
    required ObjectId serviceId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final updatedAt = DateTime.now().toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'start_at': <String, dynamic>{r'$gt': now.toUtc()},
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'service_id': serviceId,
          'start_at': startAt.toUtc(),
          'end_at': endAt.toUtc(),
          'updated_at': updatedAt,
        },
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const AvailabilityWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return findOwnedFutureById(
      id: id,
      cleanerUserId: cleanerUserId,
      now: now,
    );
  }

  @override
  Future<bool> deleteOwnedFuture({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  }) async {
    final result = await _documents.deleteOne(<String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
      'start_at': <String, dynamic>{r'$gt': now.toUtc()},
    });
    if (!result.isSuccess && result.deleted) {
      throw const AvailabilityWriteException();
    }
    return result.deleted;
  }

  @override
  Future<List<AvailabilitySlot>> listFutureForCleanerAndService({
    required ObjectId cleanerUserId,
    required ObjectId serviceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  }) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'cleaner_user_id': cleanerUserId,
        'service_id': serviceId,
        'start_at': <String, dynamic>{
          r'$gte': from.toUtc(),
          r'$lte': to.toUtc(),
        },
      },
      sort: const <String, int>{'start_at': 1},
      limit: limit,
    );
    return documents.map(AvailabilitySlot.fromDocument).toList();
  }

  @override
  Future<List<AvailabilitySlot>> listOverlappingForCleaners({
    required Iterable<ObjectId> cleanerUserIds,
    required ObjectId serviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final ids = cleanerUserIds.toSet().toList();
    if (ids.isEmpty) {
      return const <AvailabilitySlot>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'cleaner_user_id': <String, dynamic>{r'$in': ids},
        'service_id': serviceId,
        'start_at': <String, dynamic>{r'$lt': to.toUtc()},
        'end_at': <String, dynamic>{r'$gt': from.toUtc()},
      },
    );
    return documents.map(AvailabilitySlot.fromDocument).toList();
  }

  @override
  Future<List<AvailabilitySlot>> listFutureForCleanersAndService({
    required Iterable<ObjectId> cleanerUserIds,
    required ObjectId serviceId,
    required DateTime now,
  }) async {
    final ids = cleanerUserIds.toSet().toList();
    if (ids.isEmpty) {
      return const <AvailabilitySlot>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'cleaner_user_id': <String, dynamic>{r'$in': ids},
        'service_id': serviceId,
        'start_at': <String, dynamic>{r'$gt': now.toUtc()},
      },
      sort: const <String, int>{'start_at': 1},
    );
    return documents.map(AvailabilitySlot.fromDocument).toList();
  }

  Future<AvailabilitySlot?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return AvailabilitySlot.fromDocument(document);
  }
}
