import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../../routes/api/v1/account/_middleware.dart';
import '../../../../helpers/account_route_test_utils.dart';
import '../../../../helpers/auth_route_test_utils.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const fakeSecret = 'test-access-token-secret-32bytes';
  const configured = ServerConfig(
    environment: 'test',
    allowedOrigins: <String>[],
    accessTokenSecret: fakeSecret,
  );
  const unconfigured = ServerConfig(
    environment: 'test',
    allowedOrigins: <String>[],
  );

  Future<Response> send({
    required ServerConfig config,
    required Request request,
  }) async {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<ServerConfig>()).thenReturn(config);
    return middleware((_) async => Response())(context);
  }

  Future<Map<String, dynamic>> errorBody(Response response) async {
    return jsonDecode(await response.body()) as Map<String, dynamic>;
  }

  group('account middleware authentication', () {
    test('missing Authorization returns 401', () async {
      final response = await send(
        config: configured,
        request: authorizedRequest(
          method: 'GET',
          path: '/api/v1/account/me',
        ),
      );
      final body = await errorBody(response);
      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_access_token'),
      );
      expect(
        (body['error'] as Map<String, dynamic>)['message'],
        equals('Authentication is required.'),
      );
      expectNoSensitiveAuthLeak(await response.body());
    });

    test('wrong scheme returns 401', () async {
      final response = await send(
        config: configured,
        request: authorizedRequest(
          method: 'GET',
          path: '/api/v1/account/me',
          authorization: 'Basic abc',
        ),
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('blank Bearer token returns 401', () async {
      final response = await send(
        config: configured,
        request: authorizedRequest(
          method: 'GET',
          path: '/api/v1/account/me',
          authorization: 'Bearer ',
        ),
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('invalid access token returns 401', () async {
      final response = await send(
        config: configured,
        request: authorizedRequest(
          method: 'GET',
          path: '/api/v1/account/me',
          authorization: 'Bearer not-a-valid-jwt',
        ),
      );
      final body = await errorBody(response);
      expect(response.statusCode, equals(HttpStatus.unauthorized));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('invalid_access_token'),
      );
      expect(jsonEncode(body), isNot(contains('JWT')));
      expect(jsonEncode(body), isNot(contains('expired')));
    });

    test(
      'DELETE /account/sessions without Authorization returns 401',
      () async {
        final response = await send(
          config: configured,
          request: authorizedRequest(
            method: 'DELETE',
            path: '/api/v1/account/sessions',
          ),
        );
        expect(response.statusCode, equals(HttpStatus.unauthorized));
      },
    );

    test('auth configuration unavailable returns 503', () async {
      final response = await send(
        config: unconfigured,
        request: authorizedRequest(
          method: 'GET',
          path: '/api/v1/account/me',
          authorization: 'Bearer fake-token',
        ),
      );
      final body = await errorBody(response);
      expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        equals('authentication_unavailable'),
      );
    });
  });
}
