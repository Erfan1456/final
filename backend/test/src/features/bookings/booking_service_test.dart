import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/cleaner_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/cleaner/bookings/[bookingId]/accept.dart'
    as accept_route;
import '../../../../routes/api/v1/customer/bookings/index.dart'
    as customer_bookings_route;
import '../../../helpers/account_route_test_utils.dart';
import '../../../helpers/auth_route_test_utils.dart';
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late MemoryCollectionDocumentStore addresses;
  late MemoryCollectionDocumentStore slots;
  late MemoryCollectionDocumentStore profiles;
  late MemoryCollectionDocumentStore services;
  late MemoryCollectionDocumentStore offerings;
  late MemoryCollectionDocumentStore bookings;
  late MemoryCollectionDocumentStore payments;
  late MemoryCollectionDocumentStore paymentEvents;
  late MemoryCollectionDocumentStore customerProfiles;
  late MemoryUserRepository users;
  late CustomerBookingService customerBookings;
  late CleanerBookingService cleanerBookings;
  late AuthenticatedUserContext customerScoped;
  late AuthenticatedUserContext cleanerScoped;
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId serviceId;
  late ObjectId slotId;
  late ObjectId addressId;

  var clock = marketplaceTestNow();

  AvailabilitySlot futureSlot() {
    return AvailabilitySlot(
      id: slotId,
      cleanerUserId: cleanerId,
      serviceId: serviceId,
      startAt: DateTime.utc(2026, 9, 1, 3),
      endAt: DateTime.utc(2026, 9, 1, 5),
      createdAt: marketplaceTestNow(),
      updatedAt: marketplaceTestNow(),
    );
  }

  setUp(() {
    clock = marketplaceTestNow();
    addresses = MemoryCollectionDocumentStore();
    slots = MemoryCollectionDocumentStore();
    profiles = MemoryCollectionDocumentStore();
    services = MemoryCollectionDocumentStore();
    offerings = MemoryCollectionDocumentStore();
    bookings = MemoryCollectionDocumentStore();
    payments = MemoryCollectionDocumentStore();
    paymentEvents = MemoryCollectionDocumentStore();
    customerProfiles = MemoryCollectionDocumentStore();
    users = MemoryUserRepository();
    final home = testHomeCleaningService();
    serviceId = home.id;
    services.documents.add(home.toDocument());
    final customer = fakeAuthResult().user;
    customerId = customer.id;
    cleanerId = ObjectId.fromHexString('507f1f77bcf86cd799439022');
    slotId = ObjectId.fromHexString('507f1f77bcf86cd7994390c3');
    addressId = ObjectId.fromHexString('507f1f77bcf86cd7994390a1');
    users.users.addAll([
      customer,
      testUserAccount(
        id: cleanerId,
        email: 'cleaner.book@example.com',
      ),
    ]);
    addresses.documents.add(
      testAddress(userId: customerId, id: addressId).toDocument(),
    );
    profiles.documents.add(
      testCleanerProfileRecord(userId: cleanerId).toDocument(),
    );
    offerings.documents.add(
      CleanerServiceOffering(
        id: ObjectId(),
        cleanerUserId: cleanerId,
        serviceId: serviceId,
        hourlyRateMinor: 250000,
        currencyCode: 'BDT',
        isActive: true,
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      ).toDocument(),
    );
    slots.documents.add(futureSlot().toDocument());
    customerProfiles.documents.add(
      CustomerProfile(
        id: ObjectId(),
        userId: customerId,
        fullName: 'Pat Customer',
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      ).toDocument(),
    );
    final bookingRepo = MongoBookingRepository(documents: bookings);
    final paymentRepo = MongoPaymentRepository(documents: payments);
    final cancellation = BookingCancellationOrchestrator(
      bookings: bookingRepo,
      payments: paymentRepo,
      webhooks: PaymentWebhookService(
        provider: null,
        payments: paymentRepo,
        events: MongoPaymentWebhookEventRepository(documents: paymentEvents),
        clock: () => clock,
      ),
      provider: null,
      clock: () => clock,
    );
    customerBookings = CustomerBookingService(
      addresses: MongoAddressRepository(documents: addresses),
      slots: MongoAvailabilityRepository(documents: slots),
      users: users,
      cleanerProfiles: MongoCleanerProfileRepository(documents: profiles),
      services: MongoServiceRepository(documents: services),
      offerings: MongoCleanerServiceRepository(documents: offerings),
      bookings: bookingRepo,
      cancellation: cancellation,
      clock: () => clock,
    );
    cleanerBookings = CleanerBookingService(
      bookings: bookingRepo,
      customerProfiles: MongoCustomerProfileRepository(
        documents: customerProfiles,
      ),
      cancellation: cancellation,
      clock: () => clock,
    );
    customerScoped = AuthenticatedUserContext(
      principal: fakePrincipal(),
      currentUser: customer,
    );
    cleanerScoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.cleaner),
      currentUser: testUserAccount(
        id: cleanerId,
        email: 'cleaner.book@example.com',
      ),
    );
  });

  RequestContext customerCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(customerScoped);
    when(
      () => context.read<CustomerBookingService>(),
    ).thenReturn(customerBookings);
    return context;
  }

  RequestContext cleanerCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(cleanerScoped);
    when(
      () => context.read<CleanerBookingService>(),
    ).thenReturn(cleanerBookings);
    return context;
  }

  Future<({Map<String, Object?> booking, bool created})> create({
    String key = 'idempotency-key-16',
    ObjectId? slot,
    ObjectId? address,
    Object? notes,
  }) {
    return customerBookings.createBooking(
      user: customerScoped.currentUser,
      idempotencyKeyRaw: key,
      availabilitySlotIdRaw: (slot ?? slotId).oid,
      addressIdRaw: (address ?? addressId).oid,
      customerNotesRaw: notes,
    );
  }

  group('customer booking creation', () {
    test('creates pending snapshot with integer quote and history', () async {
      final result = await create(notes: '  Bring eco supplies  ');
      expect(result.created, isTrue);
      expect(result.booking['status'], equals('pending'));
      expect(result.booking['quoted_total_minor'], equals(500000));
      expect(result.booking['hourly_rate_minor'], equals(250000));
      expect(result.booking['duration_minutes'], equals(120));
      expect(result.booking['customer_notes'], equals('Bring eco supplies'));
      expect(
        (result.booking['service_snapshot']! as Map)['slug'],
        equals('home-cleaning'),
      );
      expect(
        (result.booking['address_snapshot']! as Map)['line1'],
        equals('12 Test Street'),
      );
      expect(result.booking['status_history']! as List, hasLength(1));
      expect(
        ((result.booking['status_history']! as List).single
            as Map)['from_status'],
        isNull,
      );
      expect(result.booking['cleaner_full_name'], equals('Test Cleaner'));
      expect(jsonEncode(result.booking), isNot(contains('password')));
      expect(jsonEncode(result.booking), isNot(contains('email_normalized')));
      expect(jsonEncode(result.booking), isNot(contains('idempotency_key')));
      final stored = Booking.fromDocument(bookings.documents.single);
      expect(stored.customerUserId, equals(customerId));
      expect(stored.reservationActive, isTrue);
    });

    test('foreign address is 404 and unavailable cases are 409', () async {
      try {
        await create(address: ObjectId());
        fail('expected address not found');
      } on AddressNotFoundException {
        // expected
      }

      Future<void> expectUnavailable(Future<void> Function() action) async {
        try {
          await action();
          fail('expected unavailable');
        } on AvailabilityUnavailableException {
          // expected
        }
      }

      await expectUnavailable(() => create(slot: ObjectId()));
      slots.documents.single['start_at'] = DateTime.utc(2026, 8, 1, 3);
      await expectUnavailable(create);
      slots.documents.single['start_at'] = DateTime.utc(2026, 9, 1, 3);

      users.users[1] = testUserAccount(
        id: cleanerId,
        status: AccountStatus.suspended,
        email: 'cleaner.book@example.com',
      );
      await expectUnavailable(create);
      users.users[1] = testUserAccount(
        id: cleanerId,
        email: 'cleaner.book@example.com',
      );

      profiles.documents.single['onboarding_status'] =
          CleanerOnboardingStatus.draft.wireValue;
      await expectUnavailable(create);
      profiles.documents.single['onboarding_status'] =
          CleanerOnboardingStatus.approved.wireValue;

      services.documents.single['active'] = false;
      await expectUnavailable(create);
      services.documents.single['active'] = true;

      offerings.documents.single['is_active'] = false;
      await expectUnavailable(create);
      offerings.documents.single['is_active'] = true;
    });

    test('same-slot and overlap pre-checks are unavailable', () async {
      await create();
      try {
        await create(key: 'idempotency-key-17');
        fail('expected unavailable');
      } on AvailabilityUnavailableException {
        // expected
      }
      bookings.documents.clear();
      final otherSlot = ObjectId();
      bookings.documents.add(
        Booking(
          id: ObjectId(),
          customerUserId: ObjectId(),
          cleanerUserId: cleanerId,
          availabilitySlotId: otherSlot,
          serviceId: serviceId,
          status: BookingStatus.confirmed,
          reservationActive: true,
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
          idempotencyKey: 'other-key-16chars',
          requestFingerprint: 'b' * 64,
          startAt: DateTime.utc(2026, 9, 1, 4),
          endAt: DateTime.utc(2026, 9, 1, 6),
          statusHistory: const [],
          createdAt: marketplaceTestNow(),
          updatedAt: marketplaceTestNow(),
        ).toDocument(),
      );
      try {
        await create(key: 'idempotency-key-18');
        fail('expected overlap unavailable');
      } on AvailabilityUnavailableException {
        // expected
      }
    });

    test('idempotent replay and fingerprint conflict', () async {
      final first = await create();
      final replay = await create();
      expect(replay.created, isFalse);
      expect(replay.booking['id'], equals(first.booking['id']));
      expect(replay.booking['idempotent_replay'], isTrue);
      try {
        await create(notes: 'Different notes');
        fail('expected reuse');
      } on IdempotencyKeyReusedException {
        // expected
      }
    });

    test('duplicate-key races map to replay or unavailable', () async {
      final created = await create();
      bookings.insertResult = const DocumentInsertResult.duplicate();
      final replay = await create();
      expect(replay.booking['id'], equals(created.booking['id']));
      bookings.documents.clear();
      try {
        await create(key: 'idempotency-key-19');
        fail('expected unavailable from slot unique');
      } on AvailabilityUnavailableException {
        // expected
      }
    });
  });

  group('booking transitions', () {
    test(
      'customer cancel pending and confirmed, reject past/terminal',
      () async {
        final pending = await create();
        final pendingId = ObjectId.fromHexString(
          pending.booking['id']! as String,
        );
        final cancelled = await customerBookings.cancelBooking(
          user: customerScoped.currentUser,
          bookingId: pendingId,
          reasonRaw: 'Changed plans',
        );
        expect(cancelled['status'], equals('cancelled'));
        expect(
          (cancelled['status_history']! as List).last,
          containsPair('to_status', 'cancelled'),
        );

        bookings.documents.clear();
        await create(key: 'idempotency-key-20');
        final confirmedId = bookings.documents.single['_id'] as ObjectId;
        bookings.documents.single['status'] = 'confirmed';
        final confirmedCancel = await customerBookings.cancelBooking(
          user: customerScoped.currentUser,
          bookingId: confirmedId,
        );
        expect(confirmedCancel['status'], equals('cancelled'));

        bookings.documents.single['status'] = 'confirmed';
        bookings.documents.single['reservation_active'] = true;
        bookings.documents.single['start_at'] = DateTime.utc(2026, 8, 1, 3);
        bookings.documents.single['cancelled_at'] = null;
        try {
          await customerBookings.cancelBooking(
            user: customerScoped.currentUser,
            bookingId: confirmedId,
          );
          fail('expected invalid state');
        } on InvalidBookingStateException {
          // expected
        }

        try {
          await customerBookings.cancelBooking(
            user: customerScoped.currentUser,
            bookingId: ObjectId(),
          );
          fail('expected not found');
        } on BookingNotFoundException {
          // expected
        }
      },
    );

    test(
      'cleaner accept decline cancel start complete and invalid states',
      () async {
        await create();
        final id = bookings.documents.single['_id'] as ObjectId;
        final accepted = await cleanerBookings.accept(
          user: cleanerScoped.currentUser,
          bookingId: id,
        );
        expect(accepted['status'], equals('confirmed'));
        expect(
          (accepted['address_snapshot']! as Map)['line1'],
          equals('12 Test Street'),
        );

        bookings.documents.single['status'] = 'pending';
        bookings.documents.single['reservation_active'] = true;
        bookings.documents.single['accepted_at'] = null;
        final declined = await cleanerBookings.decline(
          user: cleanerScoped.currentUser,
          bookingId: id,
          reasonRaw: 'Fully booked that morning',
        );
        expect(declined['status'], equals('declined'));
        expect(
          (declined['address_snapshot']! as Map).containsKey('line1'),
          isFalse,
        );

        bookings.documents.single['status'] = 'confirmed';
        bookings.documents.single['reservation_active'] = true;
        bookings.documents.single['declined_at'] = null;
        final cancelled = await cleanerBookings.cancel(
          user: cleanerScoped.currentUser,
          bookingId: id,
          reasonRaw: 'Emergency absence',
        );
        expect(cancelled['status'], equals('cancelled'));

        bookings.documents.single['status'] = 'confirmed';
        bookings.documents.single['reservation_active'] = true;
        bookings.documents.single['cancelled_at'] = null;
        bookings.documents.single['start_at'] = DateTime.utc(2026, 8, 25, 11);
        bookings.documents.single['end_at'] = DateTime.utc(2026, 8, 25, 13);
        final started = await cleanerBookings.start(
          user: cleanerScoped.currentUser,
          bookingId: id,
        );
        expect(started['status'], equals('in_progress'));

        final completed = await cleanerBookings.complete(
          user: cleanerScoped.currentUser,
          bookingId: id,
        );
        expect(completed['status'], equals('completed'));

        try {
          await cleanerBookings.accept(
            user: cleanerScoped.currentUser,
            bookingId: id,
          );
          fail('expected invalid');
        } on InvalidBookingStateException {
          // expected
        }

        bookings.documents.single['status'] = 'confirmed';
        bookings.documents.single['reservation_active'] = true;
        bookings.documents.single['start_at'] = DateTime.utc(2026, 9, 1, 3);
        bookings.documents.single['end_at'] = DateTime.utc(2026, 9, 1, 5);
        try {
          await cleanerBookings.start(
            user: cleanerScoped.currentUser,
            bookingId: id,
          );
          fail('expected start before window invalid');
        } on InvalidBookingStateException {
          // expected
        }

        bookings.documents.single['start_at'] = DateTime.utc(2026, 8, 25, 8);
        bookings.documents.single['end_at'] = DateTime.utc(2026, 8, 25, 10);
        try {
          await cleanerBookings.start(
            user: cleanerScoped.currentUser,
            bookingId: id,
          );
          fail('expected start after end invalid');
        } on InvalidBookingStateException {
          // expected
        }

        try {
          await cleanerBookings.getBooking(
            user: cleanerScoped.currentUser,
            bookingId: ObjectId(),
          );
          fail('expected not found');
        } on BookingNotFoundException {
          // expected
        }
      },
    );
  });

  group('booking HTTP', () {
    test('idempotency header and replay status codes', () async {
      Future<Response> post({String? key, Object? body}) {
        return customer_bookings_route.onRequest(
          customerCtx(
            Request(
              'POST',
              Uri.parse('http://localhost/api/v1/customer/bookings'),
              headers: <String, String>{
                HttpHeaders.contentTypeHeader: 'application/json',
                if (key != null) 'idempotency-key': key,
              },
              body: jsonEncode(
                body ??
                    <String, Object?>{
                      'availability_slot_id': slotId.oid,
                      'address_id': addressId.oid,
                    },
              ),
            ),
          ),
        );
      }

      final missing = await post();
      expect(missing.statusCode, equals(HttpStatus.badRequest));
      expect(
        ((jsonDecode(await missing.body()) as Map)['error'] as Map)['code'],
        equals('idempotency_key_required'),
      );

      final invalid = await post(key: 'short');
      expect(invalid.statusCode, equals(HttpStatus.badRequest));
      expect(
        ((jsonDecode(await invalid.body()) as Map)['error'] as Map)['code'],
        equals('invalid_idempotency_key'),
      );

      final created = await post(key: 'idempotency-key-16');
      expect(created.statusCode, equals(HttpStatus.created));
      final replay = await post(key: 'idempotency-key-16');
      expect(replay.statusCode, equals(HttpStatus.ok));

      final reused = await post(
        key: 'idempotency-key-16',
        body: <String, Object?>{
          'availability_slot_id': slotId.oid,
          'address_id': addressId.oid,
          'customer_notes': 'Changed',
        },
      );
      expect(reused.statusCode, equals(HttpStatus.conflict));
      expect(
        ((jsonDecode(await reused.body()) as Map)['error'] as Map)['code'],
        equals('idempotency_key_reused'),
      );

      final malformed = await post(key: 'idempotency-key-21', body: 'nope');
      expect(malformed.statusCode, equals(HttpStatus.badRequest));
    });

    test('cleaner lifecycle routes update status', () async {
      await create();
      final id = (bookings.documents.single['_id'] as ObjectId).oid;
      final accepted = await accept_route.onRequest(
        cleanerCtx(
          Request(
            'POST',
            Uri.parse('http://localhost/api/v1/cleaner/bookings/$id/accept'),
          ),
        ),
        id,
      );
      expect(accepted.statusCode, equals(HttpStatus.ok));
    });
  });
}
