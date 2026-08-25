import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/jwt_access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/current_authenticated_user_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/role_request_authorizer.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../../routes/api/v1/admin/_middleware.dart' as admin_mw;
import '../../../../../routes/api/v1/cleaner/_middleware.dart' as cleaner_mw;
import '../../../../../routes/api/v1/customer/_middleware.dart' as customer_mw;

class _MockUsers extends Mock implements UserRepository {}

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const secret = 'test-access-token-secret-32bytes';
  final tokens = JwtAccessTokenService(secret: secret);
  final authenticator = AccessAuthenticator(tokens: tokens);
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final sessionId = ObjectId.fromHexString('507f1f77bcf86cd799439012');
  final created = DateTime.utc(2026, 8, 25, 12);
  late _MockUsers users;
  late CurrentAuthenticatedUserResolver resolver;
  late RoleRequestAuthorizer authorizer;

  setUp(() {
    users = _MockUsers();
    resolver = CurrentAuthenticatedUserResolver(users: users);
    authorizer = RoleRequestAuthorizer(
      authenticator: authenticator,
      resolver: resolver,
    );
  });

  UserAccount account({
    UserRole role = UserRole.customer,
    AccountStatus status = AccountStatus.active,
  }) {
    return UserAccount(
      id: userId,
      role: role,
      email: 'Person@example.com',
      emailNormalized: 'person@example.com',
      passwordHash: 'hashed-password-must-not-appear',
      accountStatus: status,
      emailVerified: false,
      createdAt: created,
      updatedAt: created,
    );
  }

  String bearer(UserRole jwtRole) {
    return 'Bearer ${tokens.issue(
      userId: userId,
      sessionId: sessionId,
      role: jwtRole,
    )}';
  }

  Future<Response> send({
    required Handler Function(Handler) wrap,
    required String path,
    required UserRole jwtRole,
    required UserAccount? persisted,
  }) async {
    when(() => users.findById(userId)).thenAnswer((_) async => persisted);
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(
      Request(
        'GET',
        Uri.parse('http://localhost$path'),
        headers: <String, String>{
          HttpHeaders.authorizationHeader: bearer(jwtRole),
        },
      ),
    );
    when(() => context.read<AccessAuthenticator>()).thenReturn(authenticator);
    when(
      () => context.read<CurrentAuthenticatedUserResolver>(),
    ).thenReturn(resolver);
    return wrap((_) async => Response())(context);
  }

  Future<Map<String, dynamic>> bodyOf(Response response) async {
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  group('RoleRequestAuthorizer', () {
    test('allows a customer when persisted role is customer', () async {
      when(() => users.findById(userId)).thenAnswer((_) async => account());
      final scoped = await authorizer.authorize(
        authorizationHeader: bearer(UserRole.customer),
        requiredRole: UserRole.customer,
      );
      expect(scoped.currentUser.role, equals(UserRole.customer));
      expect(scoped.principal.role, equals(UserRole.customer));
    });

    test(
      'stale JWT admin role cannot grant admin after persisted role change',
      () async {
        when(
          () => users.findById(userId),
        ).thenAnswer((_) async => account());
        expect(
          () => authorizer.authorize(
            authorizationHeader: bearer(UserRole.admin),
            requiredRole: UserRole.admin,
          ),
          throwsA(isA<ForbiddenException>()),
        );
      },
    );
  });

  group('role middleware authorization', () {
    test('valid customer JWT with persisted customer is allowed', () async {
      when(() => users.findById(userId)).thenAnswer((_) async => account());
      final scoped = await authorizer.authorize(
        authorizationHeader: bearer(UserRole.customer),
        requiredRole: UserRole.customer,
      );
      expect(scoped.currentUser.id, equals(userId));
    });

    test('cleaner on customer route is forbidden', () async {
      final response = await send(
        wrap: customer_mw.middleware,
        path: '/api/v1/customer/profile',
        jwtRole: UserRole.cleaner,
        persisted: account(role: UserRole.cleaner),
      );
      final body = await bodyOf(response);
      expect(response.statusCode, equals(HttpStatus.forbidden));
      expect((body['error'] as Map)['code'], equals('forbidden'));
    });

    test('admin on customer route is forbidden', () async {
      final response = await send(
        wrap: customer_mw.middleware,
        path: '/api/v1/customer/profile',
        jwtRole: UserRole.admin,
        persisted: account(role: UserRole.admin),
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('customer on cleaner route is forbidden', () async {
      final response = await send(
        wrap: cleaner_mw.middleware,
        path: '/api/v1/cleaner/profile',
        jwtRole: UserRole.customer,
        persisted: account(),
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('admin on cleaner route is forbidden', () async {
      final response = await send(
        wrap: cleaner_mw.middleware,
        path: '/api/v1/cleaner/profile',
        jwtRole: UserRole.admin,
        persisted: account(role: UserRole.admin),
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('customer on admin route is forbidden', () async {
      final response = await send(
        wrap: admin_mw.middleware,
        path: '/api/v1/admin/cleaners',
        jwtRole: UserRole.customer,
        persisted: account(),
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('cleaner on admin route is forbidden', () async {
      final response = await send(
        wrap: admin_mw.middleware,
        path: '/api/v1/admin/cleaners',
        jwtRole: UserRole.cleaner,
        persisted: account(role: UserRole.cleaner),
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('admin JWT with persisted admin is allowed', () async {
      when(
        () => users.findById(userId),
      ).thenAnswer((_) async => account(role: UserRole.admin));
      final scoped = await authorizer.authorize(
        authorizationHeader: bearer(UserRole.admin),
        requiredRole: UserRole.admin,
      );
      expect(scoped.currentUser.role, equals(UserRole.admin));
    });

    test('suspended current user is unavailable', () async {
      final response = await send(
        wrap: customer_mw.middleware,
        path: '/api/v1/customer/profile',
        jwtRole: UserRole.customer,
        persisted: account(status: AccountStatus.suspended),
      );
      final body = await bodyOf(response);
      expect(response.statusCode, equals(HttpStatus.forbidden));
      expect((body['error'] as Map)['code'], equals('account_unavailable'));
    });

    test('deactivated current user is unavailable', () async {
      final response = await send(
        wrap: customer_mw.middleware,
        path: '/api/v1/customer/profile',
        jwtRole: UserRole.customer,
        persisted: account(status: AccountStatus.deactivated),
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('user deleted after JWT issue is unauthenticated', () async {
      final response = await send(
        wrap: customer_mw.middleware,
        path: '/api/v1/customer/profile',
        jwtRole: UserRole.customer,
        persisted: null,
      );
      final body = await bodyOf(response);
      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect((body['error'] as Map)['code'], equals('invalid_access_token'));
    });

    test('stale JWT role does not override the persisted role', () async {
      final response = await send(
        wrap: admin_mw.middleware,
        path: '/api/v1/admin/cleaners',
        jwtRole: UserRole.admin,
        persisted: account(),
      );
      final body = await bodyOf(response);
      expect(response.statusCode, equals(HttpStatus.forbidden));
      expect((body['error'] as Map)['code'], equals('forbidden'));
      expect(
        (body['error'] as Map)['message'],
        equals('You do not have permission to perform this action.'),
      );
      expect(
        jsonEncode(body),
        isNot(contains('hashed-password-must-not-appear')),
      );
    });
  });
}
