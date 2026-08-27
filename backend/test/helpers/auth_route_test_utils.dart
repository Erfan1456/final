import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_result.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import 'fake_authentication_service.dart';

class MockRequestContext extends Mock implements RequestContext {}

AuthenticationResult fakeAuthResult({
  UserRole role = UserRole.customer,
}) {
  final createdAt = DateTime.utc(2026, 8, 25, 12);
  return AuthenticationResult(
    user: UserAccount(
      id: ObjectId.fromHexString('507f1f77bcf86cd799439011'),
      role: role,
      email: 'Person@example.com',
      emailNormalized: 'person@example.com',
      passwordHash: 'hashed-password-must-not-appear',
      accountStatus: AccountStatus.active,
      emailVerified: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
    accessToken: 'fake-access-token',
    refreshToken: 'fake-refresh-token',
  );
}

RefreshedTokens fakeRefreshedTokens() {
  return const RefreshedTokens(
    accessToken: 'fake-access-token',
    refreshToken: 'fake-rotated-refresh-token',
  );
}

SignupResult fakeSignupResult({
  UserRole role = UserRole.customer,
}) {
  final createdAt = DateTime.utc(2026, 8, 25, 12);
  return SignupResult(
    user: UserAccount(
      id: ObjectId.fromHexString('507f1f77bcf86cd799439011'),
      role: role,
      email: 'Person@example.com',
      emailNormalized: 'person@example.com',
      passwordHash: 'hashed-password-must-not-appear',
      accountStatus: AccountStatus.active,
      emailVerified: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}

RequestContext authContext({
  required FakeAuthenticationService auth,
  required Request request,
}) {
  final context = MockRequestContext();
  when(() => context.request).thenReturn(request);
  when(() => context.read<AuthenticationService>()).thenReturn(auth);
  return context;
}

Request jsonRequest({
  required String method,
  required String path,
  Object? body,
  String? contentType = 'application/json',
}) {
  final headers = <String, String>{};
  if (contentType != null) {
    headers[HttpHeaders.contentTypeHeader] = contentType;
  }
  final encoded = switch (body) {
    null => '',
    String() => body,
    _ => jsonEncode(body),
  };
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: headers,
    body: encoded,
  );
}

void expectNoSensitiveAuthLeak(String encoded) {
  expect(encoded, isNot(contains('password_hash')));
  expect(encoded, isNot(contains('passwordHash')));
  expect(encoded, isNot(contains('email_normalized')));
  expect(encoded, isNot(contains('refresh_token_hash')));
  expect(encoded, isNot(contains('used_refresh_token_hashes')));
  expect(encoded, isNot(contains('ACCESS_TOKEN_SECRET')));
  expect(encoded, isNot(contains('hashed-password-must-not-appear')));
}
