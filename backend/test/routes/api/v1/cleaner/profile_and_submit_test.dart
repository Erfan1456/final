import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/cleaner/onboarding/submit.dart'
    as submit_route;
import '../../../../../routes/api/v1/cleaner/profile.dart' as profile_route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late MemoryCollectionDocumentStore store;
  late CleanerOnboardingService service;
  late AuthenticatedUserContext scoped;
  const bio = 'Experienced residential cleaner for apartments.';

  setUp(() {
    store = MemoryCollectionDocumentStore();
    service = CleanerOnboardingService(
      profiles: MongoCleanerProfileRepository(documents: store),
    );
    scoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.cleaner),
      currentUser: fakeAuthResult(role: UserRole.cleaner).user,
    );
  });

  RequestContext ctx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<AuthenticatedUserContext>()).thenReturn(scoped);
    when(() => context.read<CleanerOnboardingService>()).thenReturn(service);
    return context;
  }

  Map<String, Object?> body() => <String, Object?>{
    'full_name': 'Test Cleaner',
    'phone_e164': '+15555550100',
    'bio': bio,
    'years_experience': 3,
    'service_area': 'Dhaka North',
  };

  group('cleaner profile and submit', () {
    test('GET without profile returns null', () async {
      final response = await profile_route.onRequest(
        ctx(accountRequest(method: 'GET', path: '/api/v1/cleaner/profile')),
      );
      final decoded = jsonDecode(await response.body()) as Map;
      expect(response.statusCode, equals(HttpStatus.ok));
      expect((decoded['data'] as Map)['profile'], isNull);
    });

    test('PUT creates draft and POST submit becomes pending', () async {
      final saved = await profile_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/profile',
            body: body(),
          ),
        ),
      );
      expect(saved.statusCode, equals(HttpStatus.ok));
      expect(
        (((jsonDecode(await saved.body()) as Map)['data'] as Map)['profile']
            as Map)['onboarding_status'],
        equals('draft'),
      );

      final submitted = await submit_route.onRequest(
        ctx(
          accountRequest(
            method: 'POST',
            path: '/api/v1/cleaner/onboarding/submit',
          ),
        ),
      );
      expect(submitted.statusCode, equals(HttpStatus.ok));
      expect(
        (((jsonDecode(await submitted.body()) as Map)['data'] as Map)['profile']
            as Map)['onboarding_status'],
        equals('pending'),
      );

      final locked = await profile_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/profile',
            body: body(),
          ),
        ),
      );
      expect(locked.statusCode, equals(HttpStatus.conflict));
      expect(
        ((jsonDecode(await locked.body()) as Map)['error'] as Map)['code'],
        equals('cleaner_profile_locked'),
      );

      final again = await submit_route.onRequest(
        ctx(
          accountRequest(
            method: 'POST',
            path: '/api/v1/cleaner/onboarding/submit',
          ),
        ),
      );
      expect(again.statusCode, equals(HttpStatus.conflict));
      expect(
        ((jsonDecode(await again.body()) as Map)['error'] as Map)['code'],
        equals('invalid_onboarding_state'),
      );
    });

    test('submit without profile is 409', () async {
      final response = await submit_route.onRequest(
        ctx(
          accountRequest(
            method: 'POST',
            path: '/api/v1/cleaner/onboarding/submit',
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.conflict));
      expect(
        ((jsonDecode(await response.body()) as Map)['error'] as Map)['code'],
        equals('cleaner_profile_required'),
      );
    });

    test('validation failure is 400', () async {
      final response = await profile_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/cleaner/profile',
            body: <String, Object?>{
              ...body(),
              'years_experience': 3.5,
            },
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
