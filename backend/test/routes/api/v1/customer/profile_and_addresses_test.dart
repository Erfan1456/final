import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../../routes/api/v1/customer/addresses/[addressId]/default.dart'
    as default_route;
import '../../../../../routes/api/v1/customer/addresses/[addressId]/index.dart'
    as address_route;
import '../../../../../routes/api/v1/customer/addresses/index.dart'
    as addresses_route;
import '../../../../../routes/api/v1/customer/profile.dart' as profile_route;
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';
import '../../../../helpers/memory_collection_store.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late MemoryCollectionDocumentStore profiles;
  late MemoryCollectionDocumentStore addresses;
  late CustomerAccountService service;
  late AuthenticatedUserContext scoped;

  setUp(() {
    profiles = MemoryCollectionDocumentStore();
    addresses = MemoryCollectionDocumentStore();
    service = CustomerAccountService(
      profiles: MongoCustomerProfileRepository(documents: profiles),
      addresses: MongoAddressRepository(documents: addresses),
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
    when(() => context.read<CustomerAccountService>()).thenReturn(service);
    return context;
  }

  Future<Map<String, dynamic>> decode(Response response) async {
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  group('GET/PUT /api/v1/customer/profile', () {
    test('GET returns null profile', () async {
      final response = await profile_route.onRequest(
        ctx(accountRequest(method: 'GET', path: '/api/v1/customer/profile')),
      );
      final body = await decode(response);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['success'], isTrue);
      expect((body['data'] as Map)['profile'], isNull);
    });

    test('PUT creates then GET returns the profile', () async {
      final created = await profile_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/customer/profile',
            body: <String, Object?>{
              'full_name': 'Test Customer',
              'phone_e164': '+15555550100',
              'user_id': 'should-be-ignored',
            },
          ),
        ),
      );
      expect(created.statusCode, equals(HttpStatus.ok));
      final body = await decode(created);
      final profile = (body['data'] as Map)['profile'] as Map;
      expect(profile['full_name'], equals('Test Customer'));
      expect(profile['user_id'], equals(scoped.currentUser.id.oid));
      expect(jsonEncode(body), isNot(contains('password')));

      final fetched = await profile_route.onRequest(
        ctx(accountRequest(method: 'GET', path: '/api/v1/customer/profile')),
      );
      expect(
        ((jsonDecode(await fetched.body()) as Map)['data'] as Map)['profile'],
        isNotNull,
      );
    });

    test('PUT rejects invalid full name', () async {
      final response = await profile_route.onRequest(
        ctx(
          jsonRequest(
            method: 'PUT',
            path: '/api/v1/customer/profile',
            body: <String, Object?>{'full_name': 'A'},
          ),
        ),
      );
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('unsupported method is 405', () async {
      final response = await profile_route.onRequest(
        ctx(accountRequest(method: 'POST', path: '/api/v1/customer/profile')),
      );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });

  group('customer addresses routes', () {
    test('POST creates, GET lists with computed is_default', () async {
      await service.upsertProfile(
        userId: scoped.currentUser.id,
        fullName: 'Test Customer',
        phoneE164: null,
      );
      final created = await addresses_route.onRequest(
        ctx(
          jsonRequest(
            method: 'POST',
            path: '/api/v1/customer/addresses',
            body: <String, Object?>{
              'label': 'Home',
              'line1': '1 Test Street',
              'city': 'Dhaka',
              'region': 'Dhaka',
              'postal_code': '1205',
              'country_code': 'bd',
            },
          ),
        ),
      );
      expect(created.statusCode, equals(HttpStatus.created));
      final address =
          ((jsonDecode(await created.body()) as Map)['data'] as Map)['address']
              as Map;
      expect(address['country_code'], equals('BD'));
      expect(address['is_default'], isFalse);
      final id = address['id'] as String;

      await default_route.onRequest(
        ctx(
          accountRequest(
            method: 'PUT',
            path: '/api/v1/customer/addresses/$id/default',
          ),
        ),
        id,
      );
      final listed = await addresses_route.onRequest(
        ctx(accountRequest(method: 'GET', path: '/api/v1/customer/addresses')),
      );
      final items =
          ((jsonDecode(await listed.body()) as Map)['data'] as Map)['addresses']
              as List;
      expect((items.first as Map)['is_default'], isTrue);
    });

    test('foreign address get/update/delete/default are 404', () async {
      final other = await MongoAddressRepository(documents: addresses).create(
        userId: ObjectId.fromHexString('507f1f77bcf86cd799439099'),
        data: const AddressWriteData(
          label: 'Other',
          line1: '9 Other Street',
          city: 'Dhaka',
          region: 'Dhaka',
          postalCode: '1205',
          countryCode: 'BD',
        ),
      );
      final id = other.id.oid;
      final got = await address_route.onRequest(
        ctx(
          accountRequest(
            method: 'GET',
            path: '/api/v1/customer/addresses/$id',
          ),
        ),
        id,
      );
      expect(got.statusCode, equals(HttpStatus.notFound));
      expect(
        ((jsonDecode(await got.body()) as Map)['error'] as Map)['code'],
        equals('address_not_found'),
      );
    });

    test('set default without profile is 409', () async {
      final created = await addresses_route.onRequest(
        ctx(
          jsonRequest(
            method: 'POST',
            path: '/api/v1/customer/addresses',
            body: <String, Object?>{
              'label': 'Home',
              'line1': '1 Test Street',
              'city': 'Dhaka',
              'region': 'Dhaka',
              'postal_code': '1205',
              'country_code': 'BD',
            },
          ),
        ),
      );
      final id =
          (((jsonDecode(await created.body()) as Map)['data'] as Map)['address']
                  as Map)['id']
              as String;
      final response = await default_route.onRequest(
        ctx(
          accountRequest(
            method: 'PUT',
            path: '/api/v1/customer/addresses/$id/default',
          ),
        ),
        id,
      );
      expect(response.statusCode, equals(HttpStatus.conflict));
      expect(
        ((jsonDecode(await response.body()) as Map)['error'] as Map)['code'],
        equals('customer_profile_required'),
      );
    });

    test('malformed address id is 404', () async {
      final response = await address_route.onRequest(
        ctx(
          accountRequest(
            method: 'GET',
            path: '/api/v1/customer/addresses/not-an-id',
          ),
        ),
        'not-an-id',
      );
      expect(response.statusCode, equals(HttpStatus.notFound));
    });
  });
}
