import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';

import '../../../helpers/auth_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  late Dio dio;
  late AuthApi api;
  late RequestOptions? lastRequest;

  setUp(() {
    lastRequest = null;
    dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    api = AuthApi(plain: dio, authenticated: dio);
  });

  void useHandler(Future<ResponseBody> Function(RequestOptions) handler) {
    dio.httpClientAdapter = _Adapter((options) {
      lastRequest = options;
      return handler(options);
    });
  }

  Map<String, dynamic> tokensJson() {
    return <String, dynamic>{
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'token_type': 'Bearer',
      'expires_in': 900,
    };
  }

  group('AuthApi success parsing', () {
    test('signup success', () async {
      final user = testUser();
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/signup'));
        expect(options.data['password'], equals('fifteenCharsPass'));
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'user': userJson(user),
            'tokens': tokensJson(),
          }),
          201,
        );
      });

      final result = await api.signUp(
        email: 'person@example.com',
        password: 'fifteenCharsPass',
        role: 'customer',
      );
      expect(result.user.email, equals('person@example.com'));
      expect(result.tokens.accessToken, equals('access-token'));
    });

    test('login success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/login'));
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'user': userJson(testUser()),
            'tokens': tokensJson(),
          }),
          200,
        );
      });
      final result = await api.login(
        email: 'person@example.com',
        password: 'password',
      );
      expect(result.user.id, equals('507f1f77bcf86cd799439011'));
    });

    test('refresh success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/refresh'));
        expect(options.data['refresh_token'], equals('refresh-token'));
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'tokens': <String, dynamic>{
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'token_type': 'Bearer',
              'expires_in': 900,
            },
          }),
          200,
        );
      });
      final pair = await api.refresh('refresh-token');
      expect(pair.accessToken, equals('new-access'));
      expect(pair.refreshToken, equals('new-refresh'));
    });

    test('logout success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/logout'));
        return jsonBody(
          successEnvelope(<String, bool>{'logged_out': true}),
          200,
        );
      });
      await api.logout('refresh-token');
    });

    test('me success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/account/me'));
        return jsonBody(
          successEnvelope(<String, dynamic>{'user': userJson(testUser())}),
          200,
        );
      });
      final user = await api.me();
      expect(user.role, equals('customer'));
    });

    test('logout-all success', () async {
      useHandler((options) async {
        expect(options.method, equals('DELETE'));
        expect(options.path, equals('/api/v1/account/sessions'));
        return jsonBody(
          successEnvelope(<String, bool>{'sessions_revoked': true}),
          200,
        );
      });
      await api.revokeAllSessions();
    });
  });

  group('AuthApi error mapping', () {
    Future<void> expectCode(int status, String code) async {
      useHandler((options) async {
        return jsonBody(
          errorEnvelope(code: code, message: 'ignored-internal'),
          status,
        );
      });
      try {
        await api.login(email: 'a@b.c', password: 'x');
        fail('expected AuthFailure');
      } on AuthFailure catch (error) {
        expect(error.code, equals(code));
        expect(error.toString(), isNot(contains('Dio')));
        expect(error.message, isNot(contains('password_hash')));
        expect(error.message, isNot(contains('ignored-internal')));
      }
    }

    test('maps 400 invalid_input', () => expectCode(400, 'invalid_input'));
    test(
      'maps 401 invalid_credentials',
      () => expectCode(401, 'invalid_credentials'),
    );
    test(
      'maps 403 account_unavailable',
      () => expectCode(403, 'account_unavailable'),
    );
    test('maps 409 duplicate_email', () => expectCode(409, 'duplicate_email'));
    test(
      'maps 503 authentication_unavailable',
      () => expectCode(503, 'authentication_unavailable'),
    );

    test('missing API base URL is a configuration failure', () async {
      final unconfigured = AuthApi(
        plain: Dio(BaseOptions(baseUrl: '')),
        authenticated: Dio(BaseOptions(baseUrl: '')),
      );
      expect(
        () => unconfigured.login(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'not_configured'),
        ),
      );
    });
  });

  test('last request is not logged by the API client', () {
    expect(lastRequest, isNull);
  });
}
