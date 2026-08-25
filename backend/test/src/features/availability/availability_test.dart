import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/application/cleaner_availability_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/cleaner/availability/[slotId]/index.dart'
    as slot_route;
import '../../../../routes/api/v1/cleaner/availability/index.dart'
    as availability_route;
import '../../../helpers/account_route_test_utils.dart';
import '../../../helpers/auth_route_test_utils.dart';
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late MemoryCollectionDocumentStore services;
  late MemoryCollectionDocumentStore offerings;
  late MemoryCollectionDocumentStore profiles;
  late MemoryCollectionDocumentStore slots;
  late MemoryCollectionDocumentStore bookings;
  late CleanerAvailabilityService availability;
  late AuthenticatedUserContext scoped;
  late ObjectId serviceId;
  late ObjectId userId;

  setUp(() {
    services = MemoryCollectionDocumentStore();
    offerings = MemoryCollectionDocumentStore();
    profiles = MemoryCollectionDocumentStore();
    slots = MemoryCollectionDocumentStore();
    bookings = MemoryCollectionDocumentStore();
    final home = testHomeCleaningService();
    serviceId = home.id;
    services.documents.add(home.toDocument());
    final user = fakeAuthResult(role: UserRole.cleaner).user;
    userId = user.id;
    profiles.documents.add(
      testCleanerProfileRecord(userId: userId).toDocument(),
    );
    final now = marketplaceTestNow();
    offerings.documents.add(
      CleanerServiceOffering(
        id: ObjectId(),
        cleanerUserId: userId,
        serviceId: serviceId,
        hourlyRateMinor: 250000,
        currencyCode: 'BDT',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ).toDocument(),
    );
    availability = CleanerAvailabilityService(
      policy: ApprovedCleanerPolicy(
        profiles: MongoCleanerProfileRepository(documents: profiles),
      ),
      services: MongoServiceRepository(documents: services),
      offerings: MongoCleanerServiceRepository(documents: offerings),
      slots: MongoAvailabilityRepository(documents: slots),
      bookings: MongoBookingRepository(documents: bookings),
      clock: marketplaceTestNow,
    );
    scoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.cleaner),
      currentUser: user,
    );
  });

  RequestContext ctx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<AuthenticatedUserContext>()).thenReturn(scoped);
    when(
      () => context.read<CleanerAvailabilityService>(),
    ).thenReturn(availability);
    return context;
  }

  Future<Map<String, dynamic>> decode(Response response) async {
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  Future<Response> createSlot({
    required String start,
    required String end,
    ObjectId? service,
  }) {
    return availability_route.onRequest(
      ctx(
        jsonRequest(
          method: 'POST',
          path: '/api/v1/cleaner/availability',
          body: <String, Object?>{
            'service_id': (service ?? serviceId).oid,
            'start_at': start,
            'end_at': end,
          },
        ),
      ),
    );
  }

  group('AvailabilityRepository overlap and owner selectors', () {
    test(
      'findOverlap matches crossing windows and allows adjacent ends',
      () async {
        final repo = MongoAvailabilityRepository(documents: slots);
        final first = AvailabilitySlot(
          id: ObjectId(),
          cleanerUserId: userId,
          serviceId: serviceId,
          startAt: DateTime.utc(2026, 9, 1, 3),
          endAt: DateTime.utc(2026, 9, 1, 5),
          createdAt: marketplaceTestNow(),
          updatedAt: marketplaceTestNow(),
        );
        slots.documents.add(first.toDocument());
        expect(
          await repo.findOverlap(
            cleanerUserId: userId,
            startAt: DateTime.utc(2026, 9, 1, 4),
            endAt: DateTime.utc(2026, 9, 1, 6),
          ),
          isNotNull,
        );
        expect(
          await repo.findOverlap(
            cleanerUserId: userId,
            startAt: DateTime.utc(2026, 9, 1, 5),
            endAt: DateTime.utc(2026, 9, 1, 7),
          ),
          isNull,
        );
        expect(
          await repo.findOverlap(
            cleanerUserId: userId,
            startAt: DateTime.utc(2026, 9, 1, 3),
            endAt: DateTime.utc(2026, 9, 1, 5),
            excludeId: first.id,
          ),
          isNull,
        );
      },
    );

    test('owner selectors include _id and cleaner_user_id', () async {
      final repo = MongoAvailabilityRepository(documents: slots);
      final slot = AvailabilitySlot(
        id: ObjectId(),
        cleanerUserId: userId,
        serviceId: serviceId,
        startAt: DateTime.utc(2026, 9, 1, 3),
        endAt: DateTime.utc(2026, 9, 1, 5),
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      );
      slots.documents.add(slot.toDocument());
      await repo.deleteOwnedFuture(
        id: slot.id,
        cleanerUserId: userId,
        now: marketplaceTestNow(),
      );
      expect(slots.lastDeleteSelector, containsPair('_id', slot.id));
      expect(slots.lastDeleteSelector, containsPair('cleaner_user_id', userId));
    });

    test('duplicate start insert maps to overlap', () async {
      slots.insertResult = const DocumentInsertResult.duplicate();
      final repo = MongoAvailabilityRepository(documents: slots);
      expect(
        () => repo.create(
          AvailabilitySlot(
            id: ObjectId(),
            cleanerUserId: userId,
            serviceId: serviceId,
            startAt: DateTime.utc(2026, 9, 1, 3),
            endAt: DateTime.utc(2026, 9, 1, 5),
            createdAt: marketplaceTestNow(),
            updatedAt: marketplaceTestNow(),
          ),
        ),
        throwsA(isA<AvailabilityOverlapException>()),
      );
    });
  });

  group('cleaner availability HTTP', () {
    test('creates a valid slot and normalizes timezone to UTC', () async {
      final response = await createSlot(
        start: '2026-09-01T09:00:00+06:00',
        end: '2026-09-01T11:00:00+06:00',
      );
      final body = await decode(response);
      expect(response.statusCode, equals(HttpStatus.ok));
      final slot = (body['data'] as Map)['slot'] as Map;
      expect(slot['start_at'], equals('2026-09-01T03:00:00.000Z'));
      expect(slot['end_at'], equals('2026-09-01T05:00:00.000Z'));
    });

    test(
      'rejects timezone-less, inverted, past, and invalid durations',
      () async {
        Future<String> code(String start, String end) async {
          final response = await createSlot(start: start, end: end);
          return ((jsonDecode(await response.body()) as Map)['error']
                  as Map)['code']
              as String;
        }

        expect(
          await code('2026-09-01T09:00:00', '2026-09-01T11:00:00+06:00'),
          equals('invalid_availability_window'),
        );
        expect(
          await code(
            '2026-09-01T11:00:00+06:00',
            '2026-09-01T09:00:00+06:00',
          ),
          equals('invalid_availability_window'),
        );
        expect(
          await code(
            '2026-08-01T09:00:00+06:00',
            '2026-08-01T11:00:00+06:00',
          ),
          equals('invalid_availability_window'),
        );
        expect(
          await code(
            '2026-09-01T09:00:00+06:00',
            '2026-09-01T09:45:00+06:00',
          ),
          equals('invalid_availability_window'),
        );
        expect(
          await code(
            '2026-09-01T09:00:00+06:00',
            '2026-09-01T18:00:00+06:00',
          ),
          equals('invalid_availability_window'),
        );
        expect(
          await code(
            '2026-09-01T09:00:00+06:00',
            '2026-09-01T10:15:00+06:00',
          ),
          equals('invalid_availability_window'),
        );
      },
    );

    test(
      'allows adjacent windows and rejects overlap including other services',
      () async {
        expect(
          (await createSlot(
            start: '2026-09-01T09:00:00+06:00',
            end: '2026-09-01T11:00:00+06:00',
          )).statusCode,
          equals(HttpStatus.ok),
        );
        expect(
          (await createSlot(
            start: '2026-09-01T11:00:00+06:00',
            end: '2026-09-01T13:00:00+06:00',
          )).statusCode,
          equals(HttpStatus.ok),
        );
        final overlap = await createSlot(
          start: '2026-09-01T10:00:00+06:00',
          end: '2026-09-01T12:00:00+06:00',
        );
        expect(overlap.statusCode, equals(HttpStatus.conflict));
        expect(
          ((jsonDecode(await overlap.body()) as Map)['error'] as Map)['code'],
          equals('availability_overlap'),
        );
      },
    );

    test('requires an active offering', () async {
      offerings.documents.clear();
      final response = await createSlot(
        start: '2026-09-01T09:00:00+06:00',
        end: '2026-09-01T11:00:00+06:00',
      );
      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('lists sorted slots and filters by range', () async {
      await createSlot(
        start: '2026-09-02T09:00:00+06:00',
        end: '2026-09-02T11:00:00+06:00',
      );
      await createSlot(
        start: '2026-09-01T09:00:00+06:00',
        end: '2026-09-01T11:00:00+06:00',
      );
      final listed = await availability_route.onRequest(
        ctx(
          Request(
            'GET',
            Uri.parse('http://localhost/api/v1/cleaner/availability'),
          ),
        ),
      );
      final items =
          ((jsonDecode(await listed.body()) as Map)['data'] as Map)['items']
              as List;
      expect(items, hasLength(2));
      expect(
        (items.first as Map)['start_at'],
        startsWith('2026-09-01T03:00:00'),
      );
    });

    test('get/update/delete own future slots and hide foreign ids', () async {
      final created = await createSlot(
        start: '2026-09-01T09:00:00+06:00',
        end: '2026-09-01T11:00:00+06:00',
      );
      final slotId =
          (((jsonDecode(await created.body()) as Map)['data'] as Map)['slot']
                  as Map)['id']
              as String;
      final got = await slot_route.onRequest(
        ctx(
          Request(
            'GET',
            Uri.parse('http://localhost/api/v1/cleaner/availability/$slotId'),
          ),
        ),
        slotId,
      );
      expect(got.statusCode, equals(HttpStatus.ok));

      final other = ObjectId().oid;
      final foreign = await slot_route.onRequest(
        ctx(
          Request(
            'GET',
            Uri.parse('http://localhost/api/v1/cleaner/availability/$other'),
          ),
        ),
        other,
      );
      expect(foreign.statusCode, equals(HttpStatus.notFound));
      expect(
        ((jsonDecode(await foreign.body()) as Map)['error'] as Map)['code'],
        equals('availability_not_found'),
      );

      final updated = await slot_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/availability/$slotId',
            body: <String, Object?>{
              'service_id': serviceId.oid,
              'start_at': '2026-09-01T13:00:00+06:00',
              'end_at': '2026-09-01T15:00:00+06:00',
            },
          ),
        ),
        slotId,
      );
      expect(updated.statusCode, equals(HttpStatus.ok));

      final deleted = await slot_route.onRequest(
        ctx(
          Request(
            'DELETE',
            Uri.parse('http://localhost/api/v1/cleaner/availability/$slotId'),
          ),
        ),
        slotId,
      );
      expect(deleted.statusCode, equals(HttpStatus.ok));
    });

    test('update overlap excludes the current slot', () async {
      final created = await createSlot(
        start: '2026-09-01T09:00:00+06:00',
        end: '2026-09-01T11:00:00+06:00',
      );
      final slotId =
          (((jsonDecode(await created.body()) as Map)['data'] as Map)['slot']
                  as Map)['id']
              as String;
      final same = await slot_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/availability/$slotId',
            body: <String, Object?>{
              'service_id': serviceId.oid,
              'start_at': '2026-09-01T09:00:00+06:00',
              'end_at': '2026-09-01T11:00:00+06:00',
            },
          ),
        ),
        slotId,
      );
      expect(same.statusCode, equals(HttpStatus.ok));
    });

    test('past slots cannot be mutated', () async {
      final pastId = ObjectId();
      slots.documents.add(
        AvailabilitySlot(
          id: pastId,
          cleanerUserId: userId,
          serviceId: serviceId,
          startAt: DateTime.utc(2026, 8, 1, 3),
          endAt: DateTime.utc(2026, 8, 1, 5),
          createdAt: marketplaceTestNow(),
          updatedAt: marketplaceTestNow(),
        ).toDocument(),
      );
      final response = await slot_route.onRequest(
        ctx(
          Request(
            'DELETE',
            Uri.parse(
              'http://localhost/api/v1/cleaner/availability/${pastId.oid}',
            ),
          ),
        ),
        pastId.oid,
      );
      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('future slot limit is 180', () async {
      final repo = MongoAvailabilityRepository(documents: slots);
      for (var i = 0; i < AvailabilityValidation.maxFutureSlots; i++) {
        final start = DateTime.utc(2026, 9).add(Duration(days: i));
        slots.documents.add(
          AvailabilitySlot(
            id: ObjectId(),
            cleanerUserId: userId,
            serviceId: serviceId,
            startAt: start,
            endAt: start.add(const Duration(hours: 1)),
            createdAt: marketplaceTestNow(),
            updatedAt: marketplaceTestNow(),
          ).toDocument(),
        );
      }
      expect(
        await repo.countFutureForCleaner(
          cleanerUserId: userId,
          now: marketplaceTestNow(),
        ),
        equals(180),
      );
      final response = await createSlot(
        start: '2027-03-01T09:00:00+06:00',
        end: '2027-03-01T11:00:00+06:00',
      );
      expect(response.statusCode, equals(HttpStatus.conflict));
      expect(
        ((jsonDecode(await response.body()) as Map)['error'] as Map)['code'],
        equals('availability_limit_reached'),
      );
    });
  });

  group('availability indexes', () {
    test('omits redundant cleaner_start prefix index', () async {
      final names = <String>[];
      await ensureAvailabilityIndexes(
        ensureIndex:
            ({
              required String collectionName,
              required Map<String, dynamic> keys,
              required bool unique,
              required String name,
            }) async {
              names.add(name);
            },
      );
      expect(names, contains(availabilitySlotsCleanerStartUniqueIndexName));
      expect(names, isNot(contains('availability_slots_cleaner_start')));
      expect(names, contains(availabilitySlotsServiceStartIndexName));
      expect(names, contains(availabilitySlotsCleanerServiceStartIndexName));
    });
  });

  group('reserved availability protection', () {
    test(
      'reserved slot cannot update or delete; unreserved still can',
      () async {
        final created = await createSlot(
          start: '2026-09-01T09:00:00+06:00',
          end: '2026-09-01T11:00:00+06:00',
        );
        final slotId =
            (((jsonDecode(await created.body()) as Map)['data'] as Map)['slot']
                    as Map)['id']
                as String;
        bookings.documents.add(
          Booking(
            id: ObjectId(),
            customerUserId: ObjectId(),
            cleanerUserId: userId,
            availabilitySlotId: ObjectId.fromHexString(slotId),
            serviceId: serviceId,
            status: BookingStatus.pending,
            reservationActive: true,
            durationMinutes: 120,
            hourlyRateMinor: 250000,
            quotedTotalMinor: 500000,
            currencyCode: 'BDT',
            serviceSnapshot: BookingServiceSnapshot.fromService(
              testHomeCleaningService(),
            ),
            addressSnapshot: BookingAddressSnapshot.fromAddress(
              testAddress(userId: userId),
            ),
            idempotencyKey: 'idempotency-key-16',
            requestFingerprint: 'a' * 64,
            startAt: DateTime.utc(2026, 9, 1, 3),
            endAt: DateTime.utc(2026, 9, 1, 5),
            statusHistory: const [],
            createdAt: marketplaceTestNow(),
            updatedAt: marketplaceTestNow(),
          ).toDocument(),
        );
        final updated = await slot_route.onRequest(
          ctx(
            jsonRequest(
              method: 'PUT',
              path: '/api/v1/cleaner/availability/$slotId',
              body: <String, Object?>{
                'service_id': serviceId.oid,
                'start_at': '2026-09-01T13:00:00+06:00',
                'end_at': '2026-09-01T15:00:00+06:00',
              },
            ),
          ),
          slotId,
        );
        expect(updated.statusCode, equals(HttpStatus.conflict));
        expect(
          ((jsonDecode(await updated.body()) as Map)['error'] as Map)['code'],
          equals('availability_reserved'),
        );
        final deleted = await slot_route.onRequest(
          ctx(
            Request(
              'DELETE',
              Uri.parse('http://localhost/api/v1/cleaner/availability/$slotId'),
            ),
          ),
          slotId,
        );
        expect(deleted.statusCode, equals(HttpStatus.conflict));
        final got = await slot_route.onRequest(
          ctx(
            Request(
              'GET',
              Uri.parse('http://localhost/api/v1/cleaner/availability/$slotId'),
            ),
          ),
          slotId,
        );
        expect(got.statusCode, equals(HttpStatus.ok));

        bookings.documents.clear();
        final unreservedDelete = await slot_route.onRequest(
          ctx(
            Request(
              'DELETE',
              Uri.parse('http://localhost/api/v1/cleaner/availability/$slotId'),
            ),
          ),
          slotId,
        );
        expect(unreservedDelete.statusCode, equals(HttpStatus.ok));
      },
    );
  });
}
