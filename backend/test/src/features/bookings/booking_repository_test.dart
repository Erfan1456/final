import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';

void main() {
  late MemoryCollectionDocumentStore store;
  late MongoBookingRepository repo;
  final now = marketplaceTestNow();
  final customerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c1');
  final cleanerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c2');
  final otherCustomer = ObjectId.fromHexString('507f1f77bcf86cd7994390c9');
  final slotId = ObjectId.fromHexString('507f1f77bcf86cd7994390c3');

  Booking booking({
    ObjectId? id,
    ObjectId? customer,
    ObjectId? cleaner,
    ObjectId? slot,
    BookingStatus status = BookingStatus.pending,
    DateTime? start,
    DateTime? end,
    String idempotencyKey = 'idempotency-key-16',
  }) {
    final startAt = start ?? DateTime.utc(2026, 9, 1, 3);
    return Booking(
      id: id ?? ObjectId(),
      customerUserId: customer ?? customerId,
      cleanerUserId: cleaner ?? cleanerId,
      availabilitySlotId: slot ?? slotId,
      serviceId: testHomeCleaningService().id,
      status: status,
      reservationActive: status.reservationActive,
      durationMinutes: 120,
      hourlyRateMinor: 250000,
      quotedTotalMinor: 500000,
      currencyCode: 'BDT',
      serviceSnapshot: BookingServiceSnapshot.fromService(
        testHomeCleaningService(),
      ),
      addressSnapshot: BookingAddressSnapshot.fromAddress(
        testAddress(userId: customer ?? customerId),
      ),
      idempotencyKey: idempotencyKey,
      requestFingerprint: 'a' * 64,
      startAt: startAt,
      endAt: end ?? startAt.add(const Duration(hours: 2)),
      statusHistory: [
        BookingStatusHistoryEntry(
          toStatus: BookingStatus.pending,
          actorUserId: customer ?? customerId,
          actorRole: UserRole.customer,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    store = MemoryCollectionDocumentStore();
    repo = MongoBookingRepository(documents: store);
  });

  test('ownership selectors hide foreign bookings', () async {
    final item = booking();
    store.documents.add(item.toDocument());
    expect(
      await repo.findCustomerBookingById(
        id: item.id,
        customerUserId: customerId,
      ),
      isNotNull,
    );
    expect(
      await repo.findCustomerBookingById(
        id: item.id,
        customerUserId: otherCustomer,
      ),
      isNull,
    );
    expect(
      await repo.findCleanerBookingById(id: item.id, cleanerUserId: cleanerId),
      isNotNull,
    );
    expect(
      await repo.findCleanerBookingById(
        id: item.id,
        cleanerUserId: otherCustomer,
      ),
      isNull,
    );
  });

  test('descending cursor pagination and status filter', () async {
    final older = booking(
      id: ObjectId.fromHexString('507f1f77bcf86cd799439001'),
    );
    final newer = booking(
      id: ObjectId.fromHexString('507f1f77bcf86cd7994390ff'),
      status: BookingStatus.confirmed,
    );
    store.documents.addAll([older.toDocument(), newer.toDocument()]);
    final page = await repo.listForCustomerPage(
      customerUserId: customerId,
      limit: 1,
    );
    expect(page.items.single.id, equals(newer.id));
    expect(page.nextCursor, equals(newer.id.oid));
    final next = await repo.listForCustomerPage(
      customerUserId: customerId,
      limit: 1,
      after: newer.id,
    );
    expect(next.items.single.id, equals(older.id));
    final confirmed = await repo.listForCleanerPage(
      cleanerUserId: cleanerId,
      limit: 20,
      status: BookingStatus.confirmed,
    );
    expect(confirmed.items, hasLength(1));
  });

  test('active slot and overlap queries', () async {
    final active = booking(start: DateTime.utc(2026, 9, 1, 3));
    store.documents.add(active.toDocument());
    expect(await repo.findActiveByAvailabilitySlot(slotId), isNotNull);
    expect(
      await repo.findActiveOverlapForCleaner(
        cleanerUserId: cleanerId,
        startAt: DateTime.utc(2026, 9, 1, 4),
        endAt: DateTime.utc(2026, 9, 1, 6),
      ),
      isNotNull,
    );
    expect(
      await repo.findActiveOverlapForCleaner(
        cleanerUserId: cleanerId,
        startAt: DateTime.utc(2026, 9, 1, 5),
        endAt: DateTime.utc(2026, 9, 1, 7),
      ),
      isNull,
    );
    final batch = await repo.findActiveByAvailabilitySlotIds([
      slotId,
      ObjectId(),
    ]);
    expect(batch, hasLength(1));
  });

  test('idempotency lookup and duplicate mapping', () async {
    final item = booking();
    await repo.create(item);
    expect(
      await repo.findByCustomerAndIdempotencyKey(
        customerUserId: customerId,
        idempotencyKey: 'idempotency-key-16',
      ),
      isNotNull,
    );
    store.insertResult = const DocumentInsertResult.duplicate();
    expect(
      repo.create(booking()),
      throwsA(isA<BookingDuplicateKeyException>()),
    );
  });

  test('conditional accept/decline/cancel/start/complete', () async {
    final pending = booking();
    store.documents.add(pending.toDocument());
    expect(
      (await repo.acceptPending(
        id: pending.id,
        cleanerUserId: cleanerId,
        now: now,
      ))!.status,
      equals(BookingStatus.confirmed),
    );
    expect(store.lastUpdateSelector!['status'], equals('pending'));
    expect(store.lastUpdateSelector!['reservation_active'], isTrue);

    store.documents
      ..clear()
      ..add(booking(id: pending.id).toDocument());
    final declined = await repo.declinePending(
      id: pending.id,
      cleanerUserId: cleanerId,
      now: now,
      reason: 'Schedule conflict today',
    );
    expect(declined!.status, equals(BookingStatus.declined));
    expect(declined.reservationActive, isFalse);

    store.documents
      ..clear()
      ..add(booking(id: pending.id).toDocument());
    final customerCancel = await repo.cancelByCustomer(
      id: pending.id,
      customerUserId: customerId,
      now: now,
    );
    expect(customerCancel!.status, equals(BookingStatus.cancelled));
    expect(customerCancel.statusHistory.last.fromStatus, BookingStatus.pending);

    final confirmed = booking(status: BookingStatus.confirmed);
    store.documents
      ..clear()
      ..add(confirmed.toDocument());
    final cleanerCancel = await repo.cancelByCleaner(
      id: confirmed.id,
      cleanerUserId: cleanerId,
      now: now,
      reason: 'Unable to attend',
    );
    expect(cleanerCancel!.status, equals(BookingStatus.cancelled));

    final startable = booking(
      status: BookingStatus.confirmed,
      start: DateTime.utc(2026, 8, 25, 11),
      end: DateTime.utc(2026, 8, 25, 13),
    );
    store.documents
      ..clear()
      ..add(startable.toDocument());
    final started = await repo.startConfirmed(
      id: startable.id,
      cleanerUserId: cleanerId,
      now: now,
    );
    expect(started!.status, equals(BookingStatus.inProgress));
    expect(started.reservationActive, isTrue);

    store.documents
      ..clear()
      ..add(
        booking(
          id: startable.id,
          status: BookingStatus.inProgress,
        ).toDocument(),
      );
    final completed = await repo.completeInProgress(
      id: startable.id,
      cleanerUserId: cleanerId,
      now: now,
    );
    expect(completed!.status, equals(BookingStatus.completed));
    expect(completed.reservationActive, isFalse);
    expect(completed.statusHistory.last.toStatus, BookingStatus.completed);
  });

  test('mismatched conditional selectors match zero', () async {
    store.documents.add(booking(status: BookingStatus.completed).toDocument());
    final id = store.documents.single['_id'] as ObjectId;
    expect(
      await repo.acceptPending(id: id, cleanerUserId: cleanerId, now: now),
      isNull,
    );
  });
}
