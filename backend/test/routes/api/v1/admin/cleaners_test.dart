import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../../routes/api/v1/admin/cleaners/[userId]/approve.dart'
    as approve_route;
import '../../../../../routes/api/v1/admin/cleaners/[userId]/index.dart'
    as detail_route;
import '../../../../../routes/api/v1/admin/cleaners/[userId]/reject.dart'
    as reject_route;
import '../../../../../routes/api/v1/admin/cleaners/index.dart' as list_route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

class _MemoryUsers implements UserDocumentStore {
  final documents = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) async {
    for (final document in documents) {
      if (document['_id'] == selector['_id']) {
        return Map<String, dynamic>.from(document);
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> findMany(
    Map<String, dynamic> selector,
  ) async {
    final ids = (selector['_id'] as Map)[r'$in'] as List;
    return [
      for (final document in documents)
        if (ids.contains(document['_id'])) Map<String, dynamic>.from(document),
    ];
  }

  @override
  Future<UserInsertResult> insertOne(Map<String, dynamic> document) async {
    documents.add(document);
    return const UserInsertResult.success();
  }

  @override
  Future<UserUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  }) async {
    return const UserUpdateResult.failed();
  }
}

void main() {
  late MemoryCollectionDocumentStore profiles;
  late _MemoryUsers users;
  late AdminCleanerReviewService service;
  late AuthenticatedUserContext scoped;
  final cleanerUserId = ObjectId.fromHexString('507f1f77bcf86cd799439077');
  final created = DateTime.utc(2026, 8, 25, 12);

  setUp(() {
    profiles = MemoryCollectionDocumentStore();
    users = _MemoryUsers();
    service = AdminCleanerReviewService(
      profiles: MongoCleanerProfileRepository(documents: profiles),
      users: MongoUserRepository(documents: users),
    );
    scoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.admin),
      currentUser: fakeAuthResult(role: UserRole.admin).user,
    );
  });

  RequestContext ctx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<AuthenticatedUserContext>()).thenReturn(scoped);
    when(() => context.read<AdminCleanerReviewService>()).thenReturn(service);
    return context;
  }

  void seedPending() {
    users.documents.add(
      UserAccount(
        id: cleanerUserId,
        role: UserRole.cleaner,
        email: 'pending.cleaner@example.com',
        emailNormalized: 'pending.cleaner@example.com',
        passwordHash: 'hashed-password-must-not-appear',
        accountStatus: AccountStatus.active,
        emailVerified: false,
        createdAt: created,
        updatedAt: created,
      ).toDocument(),
    );
    profiles.documents.add(
      CleanerProfile(
        id: ObjectId.fromHexString('507f1f77bcf86cd799439078'),
        userId: cleanerUserId,
        fullName: 'Pending Cleaner',
        bio: 'Experienced residential cleaner for apartments.',
        yearsExperience: 2,
        serviceArea: 'Dhaka',
        onboardingStatus: CleanerOnboardingStatus.pending,
        submittedAt: created,
        createdAt: created,
        updatedAt: created,
      ).toDocument(),
    );
  }

  group('admin cleaner review routes', () {
    test('GET list defaults to pending', () async {
      seedPending();
      final response = await list_route.onRequest(
        ctx(accountRequest(method: 'GET', path: '/api/v1/admin/cleaners')),
      );
      final body = jsonDecode(await response.body()) as Map;
      expect(response.statusCode, equals(HttpStatus.ok));
      final items = (body['data'] as Map)['items'] as List;
      expect(items, hasLength(1));
      expect(
        (items.first as Map)['email'],
        equals('pending.cleaner@example.com'),
      );
      expect(
        jsonEncode(body),
        isNot(contains('hashed-password-must-not-appear')),
      );
    });

    test('GET detail and missing application', () async {
      seedPending();
      final found = await detail_route.onRequest(
        ctx(
          accountRequest(
            method: 'GET',
            path: '/api/v1/admin/cleaners/${cleanerUserId.oid}',
          ),
        ),
        cleanerUserId.oid,
      );
      expect(found.statusCode, equals(HttpStatus.ok));

      final missing = await detail_route.onRequest(
        ctx(
          accountRequest(
            method: 'GET',
            path: '/api/v1/admin/cleaners/507f1f77bcf86cd799439000',
          ),
        ),
        '507f1f77bcf86cd799439000',
      );
      expect(missing.statusCode, equals(HttpStatus.notFound));
    });

    test('POST approve pending', () async {
      seedPending();
      final response = await approve_route.onRequest(
        ctx(
          accountRequest(
            method: 'POST',
            path: '/api/v1/admin/cleaners/${cleanerUserId.oid}/approve',
          ),
        ),
        cleanerUserId.oid,
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        (((jsonDecode(await response.body()) as Map)['data'] as Map)['profile']
            as Map)['onboarding_status'],
        equals('approved'),
      );
    });

    test('POST reject pending', () async {
      seedPending();
      final response = await reject_route.onRequest(
        ctx(
          jsonRequest(
            method: 'POST',
            path: '/api/v1/admin/cleaners/${cleanerUserId.oid}/reject',
            body: <String, String>{'reason': 'Documents were incomplete.'},
          ),
        ),
        cleanerUserId.oid,
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        (((jsonDecode(await response.body()) as Map)['data'] as Map)['profile']
            as Map)['onboarding_status'],
        equals('rejected'),
      );
    });

    test('invalid limit is 400', () async {
      final response = await list_route.onRequest(
        ctx(
          accountRequest(
            method: 'GET',
            path: '/api/v1/admin/cleaners?limit=0',
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
