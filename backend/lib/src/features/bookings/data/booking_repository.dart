import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for marketplace bookings.
abstract class BookingRepository {
  /// Finds a booking by id without an ownership filter.
  Future<Booking?> findById(ObjectId id);

  /// Finds [id] only when owned by [customerUserId].
  Future<Booking?> findCustomerBookingById({
    required ObjectId id,
    required ObjectId customerUserId,
  });

  /// Finds [id] only when assigned to [cleanerUserId].
  Future<Booking?> findCleanerBookingById({
    required ObjectId id,
    required ObjectId cleanerUserId,
  });

  /// Finds a booking by customer and idempotency key.
  Future<Booking?> findByCustomerAndIdempotencyKey({
    required ObjectId customerUserId,
    required String idempotencyKey,
  });

  /// Customer list page, `_id` descending, optional status filter.
  Future<BookingPage> listForCustomerPage({
    required ObjectId customerUserId,
    required int limit,
    BookingStatus? status,
    ObjectId? after,
  });

  /// Cleaner list page, `_id` descending, optional status filter.
  Future<BookingPage> listForCleanerPage({
    required ObjectId cleanerUserId,
    required int limit,
    BookingStatus? status,
    ObjectId? after,
  });

  /// Active reservation for [availabilitySlotId], if any.
  Future<Booking?> findActiveByAvailabilitySlot(ObjectId availabilitySlotId);

  /// Active reservations for the given slot ids. One query, not N+1.
  Future<List<Booking>> findActiveByAvailabilitySlotIds(
    Iterable<ObjectId> availabilitySlotIds,
  );

  /// One active overlapping booking for [cleanerUserId], if any.
  Future<Booking?> findActiveOverlapForCleaner({
    required ObjectId cleanerUserId,
    required DateTime startAt,
    required DateTime endAt,
  });

  /// Inserts [booking]. Duplicate unique keys are reported.
  Future<Booking> create(Booking booking);

  /// Conditional pending → confirmed for the owning cleaner.
  Future<Booking?> acceptPending({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Conditional pending → declined for the owning cleaner.
  Future<Booking?> declinePending({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
    required String reason,
  });

  /// Conditional customer cancel of pending/confirmed before [now].
  Future<Booking?> cancelByCustomer({
    required ObjectId id,
    required ObjectId customerUserId,
    required DateTime now,
    String? reason,
  });

  /// Conditional cleaner cancel of confirmed before [now].
  Future<Booking?> cancelByCleaner({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
    required String reason,
  });

  /// Conditional confirmed → in_progress inside the slot window.
  Future<Booking?> startConfirmed({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Conditional in_progress → completed.
  Future<Booking?> completeInProgress({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  });

  /// Admin list page, `_id` descending.
  Future<BookingPage> adminPage({
    required int limit,
    BookingStatus? status,
    ObjectId? customerUserId,
    ObjectId? cleanerUserId,
    ObjectId? serviceId,
    DateTime? from,
    DateTime? to,
    ObjectId? after,
  });

  /// Conditional pending/confirmed cancel by an administrator.
  Future<Booking?> cancelByAdmin({
    required ObjectId id,
    required ObjectId adminUserId,
    required DateTime now,
    required String reason,
  });

  /// Count of bookings for [customerUserId].
  Future<int> countForCustomer(ObjectId customerUserId);

  /// Count of bookings for [cleanerUserId].
  Future<int> countForCleaner(ObjectId cleanerUserId);
}

/// MongoDB implementation of [BookingRepository].
class MongoBookingRepository implements BookingRepository {
  /// Creates a repository over [documents].
  MongoBookingRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the bookings collection on [db].
  factory MongoBookingRepository.fromDb(Db db) {
    return MongoBookingRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.bookings),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<Booking?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<Booking?> findCustomerBookingById({
    required ObjectId id,
    required ObjectId customerUserId,
  }) {
    return _find(<String, dynamic>{
      '_id': id,
      'customer_user_id': customerUserId,
    });
  }

  @override
  Future<Booking?> findCleanerBookingById({
    required ObjectId id,
    required ObjectId cleanerUserId,
  }) {
    return _find(<String, dynamic>{
      '_id': id,
      'cleaner_user_id': cleanerUserId,
    });
  }

  @override
  Future<Booking?> findByCustomerAndIdempotencyKey({
    required ObjectId customerUserId,
    required String idempotencyKey,
  }) {
    return _find(<String, dynamic>{
      'customer_user_id': customerUserId,
      'idempotency_key': idempotencyKey,
    });
  }

  @override
  Future<BookingPage> listForCustomerPage({
    required ObjectId customerUserId,
    required int limit,
    BookingStatus? status,
    ObjectId? after,
  }) {
    return _listPage(
      ownerField: 'customer_user_id',
      ownerId: customerUserId,
      limit: limit,
      status: status,
      after: after,
    );
  }

  @override
  Future<BookingPage> listForCleanerPage({
    required ObjectId cleanerUserId,
    required int limit,
    BookingStatus? status,
    ObjectId? after,
  }) {
    return _listPage(
      ownerField: 'cleaner_user_id',
      ownerId: cleanerUserId,
      limit: limit,
      status: status,
      after: after,
    );
  }

  @override
  Future<Booking?> findActiveByAvailabilitySlot(ObjectId availabilitySlotId) {
    return _find(<String, dynamic>{
      'availability_slot_id': availabilitySlotId,
      'reservation_active': true,
    });
  }

  @override
  Future<List<Booking>> findActiveByAvailabilitySlotIds(
    Iterable<ObjectId> availabilitySlotIds,
  ) async {
    final ids = availabilitySlotIds.toSet().toList();
    if (ids.isEmpty) {
      return const <Booking>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'availability_slot_id': <String, dynamic>{r'$in': ids},
        'reservation_active': true,
      },
    );
    return documents.map(Booking.fromDocument).toList();
  }

  @override
  Future<Booking?> findActiveOverlapForCleaner({
    required ObjectId cleanerUserId,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    return _find(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
      'reservation_active': true,
      'start_at': <String, dynamic>{r'$lt': endAt.toUtc()},
      'end_at': <String, dynamic>{r'$gt': startAt.toUtc()},
    });
  }

  @override
  Future<Booking> create(Booking booking) async {
    final result = await _documents.insertOne(booking.toDocument());
    if (result.isDuplicateKey) {
      throw const BookingDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const BookingWriteException();
    }
    return booking;
  }

  @override
  Future<Booking?> acceptPending({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'status': BookingStatus.pending.wireValue,
        'reservation_active': true,
      },
      set: <String, dynamic>{
        'status': BookingStatus.confirmed.wireValue,
        'reservation_active': true,
        'accepted_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.pending,
        toStatus: BookingStatus.confirmed,
        actorUserId: cleanerUserId,
        actorRole: UserRole.cleaner,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Booking?> declinePending({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
    required String reason,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'status': BookingStatus.pending.wireValue,
        'reservation_active': true,
      },
      set: <String, dynamic>{
        'status': BookingStatus.declined.wireValue,
        'reservation_active': false,
        'declined_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.pending,
        toStatus: BookingStatus.declined,
        actorUserId: cleanerUserId,
        actorRole: UserRole.cleaner,
        reason: reason,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Booking?> cancelByCustomer({
    required ObjectId id,
    required ObjectId customerUserId,
    required DateTime now,
    String? reason,
  }) async {
    final utc = now.toUtc();
    final pending = await _transition(
      selector: <String, dynamic>{
        '_id': id,
        'customer_user_id': customerUserId,
        'status': BookingStatus.pending.wireValue,
        'reservation_active': true,
        'start_at': <String, dynamic>{r'$gt': utc},
      },
      set: <String, dynamic>{
        'status': BookingStatus.cancelled.wireValue,
        'reservation_active': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.pending,
        toStatus: BookingStatus.cancelled,
        actorUserId: customerUserId,
        actorRole: UserRole.customer,
        reason: reason,
        createdAt: utc,
      ),
    );
    if (pending != null) {
      return pending;
    }
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'customer_user_id': customerUserId,
        'status': BookingStatus.confirmed.wireValue,
        'reservation_active': true,
        'start_at': <String, dynamic>{r'$gt': utc},
      },
      set: <String, dynamic>{
        'status': BookingStatus.cancelled.wireValue,
        'reservation_active': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.confirmed,
        toStatus: BookingStatus.cancelled,
        actorUserId: customerUserId,
        actorRole: UserRole.customer,
        reason: reason,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Booking?> cancelByCleaner({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
    required String reason,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'status': BookingStatus.confirmed.wireValue,
        'reservation_active': true,
        'start_at': <String, dynamic>{r'$gt': utc},
      },
      set: <String, dynamic>{
        'status': BookingStatus.cancelled.wireValue,
        'reservation_active': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.confirmed,
        toStatus: BookingStatus.cancelled,
        actorUserId: cleanerUserId,
        actorRole: UserRole.cleaner,
        reason: reason,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Booking?> startConfirmed({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'status': BookingStatus.confirmed.wireValue,
        'reservation_active': true,
        'start_at': <String, dynamic>{r'$lte': utc},
        'end_at': <String, dynamic>{r'$gt': utc},
      },
      set: <String, dynamic>{
        'status': BookingStatus.inProgress.wireValue,
        'reservation_active': true,
        'started_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.confirmed,
        toStatus: BookingStatus.inProgress,
        actorUserId: cleanerUserId,
        actorRole: UserRole.cleaner,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<Booking?> completeInProgress({
    required ObjectId id,
    required ObjectId cleanerUserId,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'cleaner_user_id': cleanerUserId,
        'status': BookingStatus.inProgress.wireValue,
        'reservation_active': true,
      },
      set: <String, dynamic>{
        'status': BookingStatus.completed.wireValue,
        'reservation_active': false,
        'completed_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.inProgress,
        toStatus: BookingStatus.completed,
        actorUserId: cleanerUserId,
        actorRole: UserRole.cleaner,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<BookingPage> adminPage({
    required int limit,
    BookingStatus? status,
    ObjectId? customerUserId,
    ObjectId? cleanerUserId,
    ObjectId? serviceId,
    DateTime? from,
    DateTime? to,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{};
    if (status != null) {
      selector['status'] = status.wireValue;
    }
    if (customerUserId != null) {
      selector['customer_user_id'] = customerUserId;
    }
    if (cleanerUserId != null) {
      selector['cleaner_user_id'] = cleanerUserId;
    }
    if (serviceId != null) {
      selector['service_id'] = serviceId;
    }
    if (from != null || to != null) {
      selector['start_at'] = <String, dynamic>{
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
    final items = page.map(Booking.fromDocument).toList();
    return BookingPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  @override
  Future<Booking?> cancelByAdmin({
    required ObjectId id,
    required ObjectId adminUserId,
    required DateTime now,
    required String reason,
  }) async {
    final utc = now.toUtc();
    final pending = await _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': BookingStatus.pending.wireValue,
        'reservation_active': true,
        'start_at': <String, dynamic>{r'$gt': utc},
      },
      set: <String, dynamic>{
        'status': BookingStatus.cancelled.wireValue,
        'reservation_active': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.pending,
        toStatus: BookingStatus.cancelled,
        actorUserId: adminUserId,
        actorRole: UserRole.admin,
        reason: reason,
        createdAt: utc,
      ),
    );
    if (pending != null) {
      return pending;
    }
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': BookingStatus.confirmed.wireValue,
        'reservation_active': true,
        'start_at': <String, dynamic>{r'$gt': utc},
      },
      set: <String, dynamic>{
        'status': BookingStatus.cancelled.wireValue,
        'reservation_active': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
      history: BookingStatusHistoryEntry(
        fromStatus: BookingStatus.confirmed,
        toStatus: BookingStatus.cancelled,
        actorUserId: adminUserId,
        actorRole: UserRole.admin,
        reason: reason,
        createdAt: utc,
      ),
    );
  }

  @override
  Future<int> countForCustomer(ObjectId customerUserId) {
    return _documents.count(<String, dynamic>{
      'customer_user_id': customerUserId,
    });
  }

  @override
  Future<int> countForCleaner(ObjectId cleanerUserId) {
    return _documents.count(<String, dynamic>{
      'cleaner_user_id': cleanerUserId,
    });
  }

  Future<BookingPage> _listPage({
    required String ownerField,
    required ObjectId ownerId,
    required int limit,
    required BookingStatus? status,
    required ObjectId? after,
  }) async {
    final selector = <String, dynamic>{ownerField: ownerId};
    if (status != null) {
      selector['status'] = status.wireValue;
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
    final items = page.map(Booking.fromDocument).toList();
    return BookingPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  Future<Booking?> _transition({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> set,
    required BookingStatusHistoryEntry history,
  }) async {
    final result = await _documents.updateOne(
      selector: selector,
      update: <String, dynamic>{
        r'$set': set,
        r'$push': <String, dynamic>{'status_history': history.toDocument()},
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const BookingWriteException();
    }
    if (!result.matched) {
      return null;
    }
    final id = selector['_id'];
    if (id is! ObjectId) {
      return null;
    }
    return _find(<String, dynamic>{'_id': id});
  }

  Future<Booking?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return Booking.fromDocument(document);
  }
}

/// Shared list pagination helper used by HTTP services.
class BookingListQuery {
  /// Creates a validated list query.
  const BookingListQuery({
    required this.limit,
    this.status,
    this.after,
  });

  /// Parsed from HTTP query values.
  factory BookingListQuery.parse({
    Object? status,
    Object? limitRaw,
    Object? after,
  }) {
    return BookingListQuery(
      status: BookingValidation.optionalStatus(status),
      limit: BookingValidation.requireLimit(limitRaw),
      after: BookingValidation.optionalCursor(after),
    );
  }

  /// Optional status filter.
  final BookingStatus? status;

  /// Page size after validation.
  final int limit;

  /// Descending `_id` cursor, if any.
  final ObjectId? after;
}
