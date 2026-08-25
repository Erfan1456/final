import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_quotation.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/marketplace_test_fixtures.dart';

void main() {
  final now = marketplaceTestNow();
  final customerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c1');
  final cleanerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c2');
  final slotId = ObjectId.fromHexString('507f1f77bcf86cd7994390c3');
  final addressId = ObjectId.fromHexString('507f1f77bcf86cd7994390a1');

  Booking sample({
    BookingStatus status = BookingStatus.pending,
    String? notes,
  }) {
    return Booking(
      id: ObjectId.fromHexString('507f1f77bcf86cd7994390b1'),
      customerUserId: customerId,
      cleanerUserId: cleanerId,
      availabilitySlotId: slotId,
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
        testAddress(userId: customerId),
      ),
      customerNotes: notes,
      idempotencyKey: 'idempotency-key-16',
      requestFingerprint: 'a' * 64,
      startAt: DateTime.utc(2026, 9, 1, 3),
      endAt: DateTime.utc(2026, 9, 1, 5),
      statusHistory: [
        BookingStatusHistoryEntry(
          toStatus: BookingStatus.pending,
          actorUserId: customerId,
          actorRole: UserRole.customer,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  group('BookingStatus', () {
    test('wire values and reservation_active mapping', () {
      expect(BookingStatus.pending.wireValue, equals('pending'));
      expect(BookingStatus.confirmed.wireValue, equals('confirmed'));
      expect(BookingStatus.inProgress.wireValue, equals('in_progress'));
      expect(BookingStatus.completed.wireValue, equals('completed'));
      expect(BookingStatus.declined.wireValue, equals('declined'));
      expect(BookingStatus.cancelled.wireValue, equals('cancelled'));
      expect(BookingStatus.pending.reservationActive, isTrue);
      expect(BookingStatus.confirmed.reservationActive, isTrue);
      expect(BookingStatus.inProgress.reservationActive, isTrue);
      expect(BookingStatus.completed.reservationActive, isFalse);
      expect(BookingStatus.declined.reservationActive, isFalse);
      expect(BookingStatus.cancelled.reservationActive, isFalse);
    });
  });

  group('BookingQuotation', () {
    test('uses integer round-half-up and never doubles', () {
      expect(
        BookingQuotation.quotedTotalMinor(
          hourlyRateMinor: 250000,
          durationMinutes: 120,
        ),
        equals(500000),
      );
      expect(
        BookingQuotation.quotedTotalMinor(
          hourlyRateMinor: 100,
          durationMinutes: 90,
        ),
        equals(150),
      );
      expect(
        BookingQuotation.quotedTotalMinor(
          hourlyRateMinor: 1,
          durationMinutes: 30,
        ),
        equals(1),
      );
      expect(
        BookingQuotation.durationMinutes(
          startAt: DateTime.utc(2026, 9, 1, 3),
          endAt: DateTime.utc(2026, 9, 1, 5),
        ),
        equals(120),
      );
    });
  });

  group('BookingValidation', () {
    test('notes and idempotency key rules', () {
      expect(BookingValidation.optionalCustomerNotes('  '), isNull);
      expect(
        BookingValidation.optionalCustomerNotes('Bring keys'),
        equals('Bring keys'),
      );
      expect(
        () => BookingValidation.optionalCustomerNotes('bad\nline'),
        throwsA(isA<InvalidCustomerNotesException>()),
      );
      expect(
        BookingValidation.requireIdempotencyKey('  abcdefghijklmnop  '),
        equals('abcdefghijklmnop'),
      );
      expect(
        () => BookingValidation.requireIdempotencyKey(null),
        throwsA(isA<IdempotencyKeyRequiredException>()),
      );
      expect(
        () => BookingValidation.requireIdempotencyKey('short'),
        throwsA(isA<InvalidIdempotencyKeyException>()),
      );
      expect(
        () => BookingValidation.requireIdempotencyKey('abcdefghijklmnop\u0001'),
        throwsA(isA<InvalidIdempotencyKeyException>()),
      );
    });

    test('fingerprint is deterministic and excludes timestamps', () {
      final first = BookingValidation.requestFingerprint(
        customerUserId: customerId,
        availabilitySlotId: slotId,
        addressId: addressId,
        customerNotes: 'Park in back',
      );
      final second = BookingValidation.requestFingerprint(
        customerUserId: customerId,
        availabilitySlotId: slotId,
        addressId: addressId,
        customerNotes: 'Park in back',
      );
      expect(first, equals(second));
      expect(first, matches(RegExp(r'^[a-f0-9]{64}$')));
      final differentNotes = BookingValidation.requestFingerprint(
        customerUserId: customerId,
        availabilitySlotId: slotId,
        addressId: addressId,
        customerNotes: null,
      );
      expect(differentNotes, isNot(equals(first)));
    });
  });

  group('Booking snapshots and privacy DTOs', () {
    test('round-trips BSON and omits security fields', () {
      final booking = sample(notes: 'Leave shoes outside');
      final restored = Booking.fromDocument(booking.toDocument());
      expect(restored.status, equals(BookingStatus.pending));
      expect(restored.serviceSnapshot.billingModel, ServiceBillingModel.hourly);
      expect(restored.addressSnapshot.line1, equals('12 Test Street'));
      expect(restored.statusHistory.single.fromStatus, isNull);
      final encoded = booking.toDocument().toString();
      expect(encoded, isNot(contains('password')));
      expect(encoded, isNot(contains('email_normalized')));
      expect(encoded, isNot(contains('ACCESS_TOKEN')));
    });

    test('customer DTO is full address; cleaner pending is coarse', () {
      final pending = sample();
      final customerJson = pending.toCustomerJson(
        cleanerPublicName: 'Ada Cleaner',
      );
      expect(customerJson['cleaner_full_name'], equals('Ada Cleaner'));
      expect(
        (customerJson['address_snapshot']! as Map)['line1'],
        equals('12 Test Street'),
      );
      expect(customerJson.containsKey('idempotency_key'), isFalse);
      expect(customerJson.containsKey('request_fingerprint'), isFalse);
      final cleanerPending = pending.toCleanerJson(
        customerDisplayName: 'Customer',
      );
      expect(
        (cleanerPending['address_snapshot']! as Map).containsKey('line1'),
        isFalse,
      );
      expect(
        (cleanerPending['address_snapshot']! as Map)['city'],
        equals('Dhaka'),
      );
      final confirmed = sample(status: BookingStatus.confirmed);
      expect(
        (confirmed.toCleanerJson(
              customerDisplayName: 'Pat',
            )['address_snapshot']!
            as Map)['line1'],
        equals('12 Test Street'),
      );
    });
  });

  group('booking indexes', () {
    test(
      'requests approved indexes and omits redundant slot active index',
      () async {
        final names = <String>[];
        Map<String, dynamic>? partial;
        await ensureBookingIndexes(
          ensureIndex:
              ({
                required String collectionName,
                required Map<String, dynamic> keys,
                required bool unique,
                required String name,
                Map<String, dynamic>? partialFilterExpression,
              }) async {
                names.add(name);
                if (name == bookingsActiveAvailabilitySlotUniqueIndexName) {
                  expect(unique, isTrue);
                  expect(
                    keys,
                    equals(const <String, dynamic>{'availability_slot_id': 1}),
                  );
                  partial = partialFilterExpression;
                }
              },
        );
        expect(names, contains(bookingsActiveAvailabilitySlotUniqueIndexName));
        expect(names, contains(bookingsCustomerIdempotencyUniqueIndexName));
        expect(names, contains(bookingsCustomerIdDescIndexName));
        expect(names, contains(bookingsCleanerIdDescIndexName));
        expect(names, contains(bookingsCleanerActiveStartIndexName));
        expect(names, isNot(contains('bookings_availability_active')));
        expect(
          partial,
          equals(const <String, dynamic>{'reservation_active': true}),
        );
      },
    );
  });
}
