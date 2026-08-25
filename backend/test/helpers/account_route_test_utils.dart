import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/current_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/authenticated_principal.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

import 'auth_route_test_utils.dart';
import 'fake_current_account_service.dart';

AuthenticatedPrincipal fakePrincipal({
  UserRole role = UserRole.customer,
}) {
  return AuthenticatedPrincipal(
    userId: ObjectId.fromHexString('507f1f77bcf86cd799439011'),
    sessionId: ObjectId.fromHexString('507f1f77bcf86cd799439012'),
    role: role,
    jwtId: 'fake-jwt-id',
  );
}

RequestContext accountContext({
  required FakeCurrentAccountService account,
  required Request request,
  AuthenticatedPrincipal? principal,
}) {
  final context = MockRequestContext();
  when(() => context.request).thenReturn(request);
  when(
    () => context.read<AuthenticatedPrincipal>(),
  ).thenReturn(principal ?? fakePrincipal());
  when(() => context.read<CurrentAccountService>()).thenReturn(account);
  return context;
}

Request accountRequest({
  required String method,
  required String path,
}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
  );
}

Request authorizedRequest({
  required String method,
  required String path,
  String? authorization,
}) {
  final headers = <String, String>{};
  if (authorization != null) {
    headers[HttpHeaders.authorizationHeader] = authorization;
  }
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: headers,
  );
}
