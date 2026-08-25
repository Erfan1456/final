import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/application/cleaner_discovery_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/discovery/cleaners/[cleanerUserId]/index.dart'
    as detail_route;
import '../../../../routes/api/v1/discovery/cleaners/index.dart' as list_route;
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
  late MemoryUserRepository users;
  late CleanerDiscoveryService discovery;
  late AuthenticatedUserContext scoped;
  late ObjectId serviceId;

  setUp(() {
    services = MemoryCollectionDocumentStore();
    offerings = MemoryCollectionDocumentStore();
    profiles = MemoryCollectionDocumentStore();
    slots = MemoryCollectionDocumentStore();
    bookings = MemoryCollectionDocumentStore();
    users = MemoryUserRepository();
    final home = testHomeCleaningService();
    serviceId = home.id;
    services.documents.add(home.toDocument());
    discovery = CleanerDiscoveryService(
      services: MongoServiceRepository(documents: services),
      offerings: MongoCleanerServiceRepository(documents: offerings),
      profiles: MongoCleanerProfileRepository(documents: profiles),
      users: users,
      slots: MongoAvailabilityRepository(documents: slots),
      bookings: MongoBookingRepository(documents: bookings),
      clock: marketplaceTestNow,
    );
    scoped = AuthenticatedUserContext(
      principal: fakePrincipal(),
      currentUser: fakeAuthResult().user,
    );
  });

  RequestContext ctx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<AuthenticatedUserContext>()).thenReturn(scoped);
    when(() => context.read<CleanerDiscoveryService>()).thenReturn(discovery);
    return context;
  }

  ObjectId seedCleaner({
    required String hexSuffix,
    CleanerOnboardingStatus status = CleanerOnboardingStatus.approved,
    AccountStatus accountStatus = AccountStatus.active,
    UserRole role = UserRole.cleaner,
    bool offeringActive = true,
    int yearsExperience = 3,
    int rate = 250000,
    String currency = 'BDT',
    String name = 'Discoverable Cleaner',
    DateTime? nextStart,
  }) {
    final userId = ObjectId();
    users.users.add(
      testUserAccount(
        id: userId,
        role: role,
        status: accountStatus,
        email: 'cleaner.$hexSuffix@example.com',
      ),
    );
    profiles.documents.add(
      testCleanerProfileRecord(
        userId: userId,
        status: status,
        yearsExperience: yearsExperience,
        fullName: name,
      ).toDocument(),
    );
    offerings.documents.add(
      CleanerServiceOffering(
        id: ObjectId(),
        cleanerUserId: userId,
        serviceId: serviceId,
        hourlyRateMinor: rate,
        currencyCode: currency,
        isActive: offeringActive,
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      ).toDocument(),
    );
    if (nextStart != null) {
      slots.documents.add(
        AvailabilitySlot(
          id: ObjectId(),
          cleanerUserId: userId,
          serviceId: serviceId,
          startAt: nextStart,
          endAt: nextStart.add(const Duration(hours: 2)),
          createdAt: marketplaceTestNow(),
          updatedAt: marketplaceTestNow(),
        ).toDocument(),
      );
    }
    return userId;
  }

  Future<Map<String, dynamic>> decode(Response response) async {
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  group('discovery eligibility', () {
    test('approved active offering appears and others are hidden', () async {
      seedCleaner(hexSuffix: 'ok');
      seedCleaner(
        hexSuffix: 'draft',
        status: CleanerOnboardingStatus.draft,
      );
      seedCleaner(
        hexSuffix: 'pending',
        status: CleanerOnboardingStatus.pending,
      );
      seedCleaner(
        hexSuffix: 'rejected',
        status: CleanerOnboardingStatus.rejected,
      );
      seedCleaner(
        hexSuffix: 'suspended',
        accountStatus: AccountStatus.suspended,
      );
      seedCleaner(
        hexSuffix: 'deactivated',
        accountStatus: AccountStatus.deactivated,
      );
      seedCleaner(hexSuffix: 'inactive-offering', offeringActive: false);

      final response = await list_route.onRequest(
        ctx(
          Request(
            'GET',
            Uri.parse('http://localhost/api/v1/discovery/cleaners'),
          ),
        ),
      );
      final body = await decode(response);
      final items = (body['data'] as Map)['items'] as List;
      expect(items, hasLength(1));
      expect(
        (items.single as Map)['full_name'],
        equals('Discoverable Cleaner'),
      );
      expect(jsonEncode(body), isNot(contains('phone_e164')));
      expect(jsonEncode(body), isNot(contains('email')));
      expect(jsonEncode(body), isNot(contains('reviewed_by')));
      expect(jsonEncode(body), isNot(contains('rejection_reason')));
      expect(jsonEncode(body), isNot(contains('password')));
      expect(jsonEncode(body), isNot(contains('email_normalized')));
    });

    test('inactive platform service hides cleaners', () async {
      seedCleaner(hexSuffix: 'ok');
      services.documents
        ..clear()
        ..add(testHomeCleaningService(active: false).toDocument());
      final page = await discovery.listCleaners();
      expect(page.items, isEmpty);
    });
  });

  group('discovery filters and pagination', () {
    test(
      'filters currency, max rate, experience, and availability window',
      () async {
        seedCleaner(hexSuffix: 'bdt');
        seedCleaner(hexSuffix: 'usd', rate: 80000, currency: 'USD');
        seedCleaner(
          hexSuffix: 'exp',
          yearsExperience: 1,
          rate: 100000,
        );
        seedCleaner(
          hexSuffix: 'slot',
          rate: 200000,
          nextStart: DateTime.utc(2026, 9, 1, 3),
        );

        final currency = await discovery.listCleaners(currency: 'usd');
        expect(currency.items, hasLength(1));
        expect(currency.items.single.currencyCode, equals('USD'));

        final maxRate = await discovery.listCleaners(maxRateMinor: 200000);
        expect(
          maxRate.items.every((item) => item.hourlyRateMinor <= 200000),
          isTrue,
        );

        final experience = await discovery.listCleaners(minExperience: 3);
        expect(
          experience.items.every((item) => item.yearsExperience >= 3),
          isTrue,
        );

        final window = await discovery.listCleaners(
          availableFrom: '2026-09-01T09:00:00+06:00',
          availableTo: '2026-09-01T12:00:00+06:00',
        );
        expect(window.items, hasLength(1));

        final invalid = await list_route.onRequest(
          ctx(
            Request(
              'GET',
              Uri.parse(
                'http://localhost/api/v1/discovery/cleaners?available_from=2026-09-01T09:00:00+06:00',
              ),
            ),
          ),
        );
        expect(invalid.statusCode, equals(HttpStatus.badRequest));
        expect(
          ((jsonDecode(await invalid.body()) as Map)['error'] as Map)['code'],
          equals('invalid_availability_window'),
        );
      },
    );

    test('keyset pagination is deterministic by offering _id', () async {
      for (var i = 0; i < 3; i++) {
        seedCleaner(hexSuffix: '$i', name: 'Cleaner $i');
      }
      offerings.documents.sort((a, b) {
        final left = (a['_id'] as ObjectId).oid;
        final right = (b['_id'] as ObjectId).oid;
        return left.compareTo(right);
      });
      final first = await discovery.listCleaners(limitRaw: 2);
      expect(first.items, hasLength(2));
      expect(first.nextCursor, isNotNull);
      final second = await discovery.listCleaners(
        limitRaw: 2,
        after: first.nextCursor,
      );
      expect(second.items, hasLength(1));
      expect(second.nextCursor, isNull);
      expect(
        first.items
            .map((item) => item.cleanerUserId)
            .toSet()
            .intersection(
              second.items.map((item) => item.cleanerUserId).toSet(),
            ),
        isEmpty,
      );
    });
  });

  group('discovery detail and query efficiency', () {
    test(
      'eligible detail is private-safe and ineligible is the same 404',
      () async {
        final visible = seedCleaner(
          hexSuffix: 'visible',
          nextStart: DateTime.utc(2026, 9, 1, 3),
        );
        final hidden = seedCleaner(
          hexSuffix: 'hidden',
          status: CleanerOnboardingStatus.draft,
        );
        final ok = await detail_route.onRequest(
          ctx(
            Request(
              'GET',
              Uri.parse(
                'http://localhost/api/v1/discovery/cleaners/${visible.oid}',
              ),
            ),
          ),
          visible.oid,
        );
        final okBody = await decode(ok);
        expect(ok.statusCode, equals(HttpStatus.ok));
        expect(jsonEncode(okBody), isNot(contains('phone_e164')));
        expect(jsonEncode(okBody), isNot(contains('+15555550101')));
        expect(jsonEncode(okBody), isNot(contains('reviewed_by')));
        final availability = (okBody['data'] as Map)['availability'] as List;
        expect(availability, hasLength(1));

        Future<void> expectHidden(String id) async {
          final response = await detail_route.onRequest(
            ctx(
              Request(
                'GET',
                Uri.parse('http://localhost/api/v1/discovery/cleaners/$id'),
              ),
            ),
            id,
          );
          expect(response.statusCode, equals(HttpStatus.notFound));
          expect(
            ((jsonDecode(await response.body()) as Map)['error']
                as Map)['code'],
            equals('cleaner_not_found'),
          );
        }

        await expectHidden(hidden.oid);
        await expectHidden(ObjectId().oid);
      },
    );

    test('list processing uses batched user and profile lookups', () async {
      for (var i = 0; i < 3; i++) {
        seedCleaner(hexSuffix: 'batch$i');
      }
      profiles.findManyCalls = 0;
      users.findByIdsCalls = 0;
      await discovery.listCleaners();
      expect(users.findByIdsCalls, equals(1));
      expect(profiles.findManyCalls, equals(1));
    });

    test(
      'reserved slots are excluded from next available and detail',
      () async {
        final cleaner = seedCleaner(
          hexSuffix: 'reserved',
          nextStart: DateTime.utc(2026, 9, 1, 3),
        );
        final slotId = slots.documents.single['_id'] as ObjectId;
        bookings.documents.add(
          Booking(
            id: ObjectId(),
            customerUserId: ObjectId(),
            cleanerUserId: cleaner,
            availabilitySlotId: slotId,
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
              testAddress(userId: ObjectId()),
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
        bookings.findManyCalls = 0;
        final listed = await discovery.listCleaners();
        expect(listed.items.single.nextAvailableAt, isNull);
        expect(bookings.findManyCalls, equals(1));
        final window = await discovery.listCleaners(
          availableFrom: '2026-09-01T09:00:00+06:00',
          availableTo: '2026-09-01T12:00:00+06:00',
        );
        expect(window.items, isEmpty);
        final detail = await discovery.getCleanerDetail(cleanerUserId: cleaner);
        expect(detail.availability, isEmpty);

        bookings.documents.single['status'] = BookingStatus.cancelled.wireValue;
        bookings.documents.single['reservation_active'] = false;
        final afterRelease = await discovery.getCleanerDetail(
          cleanerUserId: cleaner,
        );
        expect(afterRelease.availability, hasLength(1));
        expect(afterRelease.availability.single.id, equals(slotId));
      },
    );
  });
}
