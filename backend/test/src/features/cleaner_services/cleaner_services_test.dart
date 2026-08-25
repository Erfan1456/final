import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/application/cleaner_service_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/cleaner/services/[serviceId]/index.dart'
    as offering_route;
import '../../../../routes/api/v1/cleaner/services/index.dart' as list_route;
import '../../../helpers/account_route_test_utils.dart';
import '../../../helpers/auth_route_test_utils.dart';
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

class _RecordingEnsureIndex {
  final calls = <String>[];

  Future<void> call({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    calls.add(name);
  }
}

void main() {
  late MemoryCollectionDocumentStore services;
  late MemoryCollectionDocumentStore offerings;
  late MemoryCollectionDocumentStore profiles;
  late CleanerServiceManagementService management;
  late AuthenticatedUserContext scoped;
  late ObjectId serviceId;

  setUp(() {
    services = MemoryCollectionDocumentStore();
    offerings = MemoryCollectionDocumentStore();
    profiles = MemoryCollectionDocumentStore();
    serviceId = testHomeCleaningService().id;
    services.documents.add(testHomeCleaningService().toDocument());
    final user = fakeAuthResult(role: UserRole.cleaner).user;
    profiles.documents.add(
      testCleanerProfileRecord(userId: user.id).toDocument(),
    );
    management = CleanerServiceManagementService(
      policy: ApprovedCleanerPolicy(
        profiles: MongoCleanerProfileRepository(documents: profiles),
      ),
      services: MongoServiceRepository(documents: services),
      offerings: MongoCleanerServiceRepository(documents: offerings),
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
      () => context.read<CleanerServiceManagementService>(),
    ).thenReturn(management);
    return context;
  }

  Future<Map<String, dynamic>> decode(Response response) async {
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  group('CleanerServiceRepository', () {
    test(
      'upsert uses cleaner+service ownership and deactivates logically',
      () async {
        final repo = MongoCleanerServiceRepository(documents: offerings);
        final userId = scoped.currentUser.id;
        final created = await repo.upsertOffering(
          cleanerUserId: userId,
          serviceId: serviceId,
          data: const CleanerServiceWriteData(
            hourlyRateMinor: 250000,
            currencyCode: 'BDT',
            isActive: true,
          ),
        );
        final updated = await repo.upsertOffering(
          cleanerUserId: userId,
          serviceId: serviceId,
          data: const CleanerServiceWriteData(
            hourlyRateMinor: 300000,
            currencyCode: 'USD',
            isActive: true,
          ),
        );
        expect(updated.id, equals(created.id));
        expect(offerings.documents, hasLength(1));
        expect(
          offerings.lastUpdateSelector,
          containsPair('cleaner_user_id', userId),
        );
        expect(
          offerings.lastUpdateSelector,
          containsPair('service_id', serviceId),
        );
        final deactivated = await repo.deactivateOffering(
          cleanerUserId: userId,
          serviceId: serviceId,
        );
        expect(deactivated!.isActive, isFalse);
        expect(offerings.documents, hasLength(1));
      },
    );
  });

  group('cleaner service HTTP', () {
    test('PUT creates, updates rate, and normalizes currency', () async {
      final created = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'bdt',
              'is_active': true,
              'cleaner_user_id': 'should-be-ignored',
            },
          ),
        ),
        serviceId.oid,
      );
      final createdBody = await decode(created);
      expect(created.statusCode, equals(HttpStatus.ok));
      expect(
        ((createdBody['data'] as Map)['offering'] as Map)['currency_code'],
        equals('BDT'),
      );

      final updated = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 260000,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      final updatedBody = await decode(updated);
      expect(
        ((updatedBody['data'] as Map)['offering'] as Map)['hourly_rate_minor'],
        equals(260000),
      );
      expect(offerings.documents, hasLength(1));
    });

    test('rejects double and string rates and bad currency', () async {
      final asDouble = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000.5,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      expect(asDouble.statusCode, equals(HttpStatus.badRequest));
      expect(
        ((jsonDecode(await asDouble.body()) as Map)['error'] as Map)['code'],
        equals('invalid_hourly_rate'),
      );

      final asString = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': '250000',
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      expect(asString.statusCode, equals(HttpStatus.badRequest));

      final badCurrency = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'BD',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      expect(
        ((jsonDecode(await badCurrency.body()) as Map)['error'] as Map)['code'],
        equals('invalid_currency_code'),
      );
    });

    test('inactive platform service is 404', () async {
      services.documents
        ..clear()
        ..add(testHomeCleaningService(active: false).toDocument());
      final response = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      expect(response.statusCode, equals(HttpStatus.notFound));
      expect(
        ((jsonDecode(await response.body()) as Map)['error'] as Map)['code'],
        equals('service_not_found'),
      );
    });

    test('DELETE deactivates and PUT can reactivate', () async {
      await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      final deleted = await offering_route.onRequest(
        ctx(
          Request(
            'DELETE',
            Uri.parse(
              'http://localhost/api/v1/cleaner/services/${serviceId.oid}',
            ),
          ),
        ),
        serviceId.oid,
      );
      expect(
        (((jsonDecode(await deleted.body()) as Map)['data'] as Map)['offering']
            as Map)['is_active'],
        isFalse,
      );
      final reactivated = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      expect(
        (((jsonDecode(await reactivated.body()) as Map)['data']
                as Map)['offering']
            as Map)['is_active'],
        isTrue,
      );
    });

    test('GET lists offerings and unapproved cleaners are blocked', () async {
      await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      final listed = await list_route.onRequest(
        ctx(
          Request('GET', Uri.parse('http://localhost/api/v1/cleaner/services')),
        ),
      );
      expect(
        ((jsonDecode(await listed.body()) as Map)['data'] as Map)['items']
            as List,
        hasLength(1),
      );

      profiles.documents
        ..clear()
        ..add(
          testCleanerProfileRecord(
            userId: scoped.currentUser.id,
            status: CleanerOnboardingStatus.pending,
          ).toDocument(),
        );
      final blocked = await offering_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/services/${serviceId.oid}',
            body: <String, Object?>{
              'hourly_rate_minor': 250000,
              'currency_code': 'BDT',
              'is_active': true,
            },
          ),
        ),
        serviceId.oid,
      );
      expect(blocked.statusCode, equals(HttpStatus.forbidden));
      expect(
        ((jsonDecode(await blocked.body()) as Map)['error'] as Map)['code'],
        equals('cleaner_not_approved'),
      );
    });
  });

  group('ensureCleanerServiceIndexes', () {
    test('requests the unique relationship and discovery indexes', () async {
      final recorder = _RecordingEnsureIndex();
      await ensureCleanerServiceIndexes(ensureIndex: recorder.call);
      expect(
        recorder.calls,
        containsAll(<String>[
          cleanerServicesCleanerServiceUniqueIndexName,
          cleanerServicesServiceActiveIdIndexName,
          cleanerServicesServiceCurrencyRateIdIndexName,
        ]),
      );
      expect(CollectionNames.cleanerServices, equals('cleaner_services'));
    });
  });
}
