import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/development_account_action.dart';

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
    test('signup success without tokens', () async {
      final user = testUser(emailVerified: false);
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/signup'));
        expect(options.data['password'], equals('fifteenCharsPass'));
        return jsonBody(
          successEnvelope(
            signupDataJson(
              user,
              developmentAction: const DevelopmentAccountAction(
                purpose: 'email_verification',
                token: 'verify-token',
              ),
            ),
          ),
          201,
        );
      });

      final result = await api.signUp(
        email: 'person@example.com',
        password: 'fifteenCharsPass',
        role: 'customer',
      );
      expect(result.user.email, equals('person@example.com'));
      expect(result.verificationRequired, isTrue);
      expect(result.developmentAction?.token, equals('verify-token'));
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

    test('request email verification success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/email-verification/request'));
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'message': 'If an account exists, a verification email was sent.',
            'development_action': <String, String>{
              'purpose': 'email_verification',
              'token': 'verify-token',
            },
          }),
          200,
        );
      });
      final result = await api.requestEmailVerification('person@example.com');
      expect(result.message, contains('verification'));
      expect(result.developmentAction?.token, equals('verify-token'));
    });

    test('verify email success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/email-verification/verify'));
        expect(options.data['token'], equals('verify-token'));
        return jsonBody(
          successEnvelope(<String, bool>{'email_verified': true}),
          200,
        );
      });
      await api.verifyEmail('verify-token');
    });

    test('request password reset success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/password-reset/request'));
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'message': 'If an account exists, reset instructions were sent.',
            'development_action': <String, String>{
              'purpose': 'password_reset',
              'token': 'reset-token',
            },
          }),
          200,
        );
      });
      final result = await api.requestPasswordReset('person@example.com');
      expect(result.developmentAction?.purpose, equals('password_reset'));
    });

    test('confirm password reset success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/auth/password-reset/confirm'));
        return jsonBody(
          successEnvelope(<String, bool>{'password_reset': true}),
          200,
        );
      });
      await api.confirmPasswordReset(
        token: 'reset-token',
        newPassword: 'fifteenCharsPass',
      );
    });

    test('change password success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/account/password/change'));
        return jsonBody(
          successEnvelope(<String, bool>{'reauthentication_required': true}),
          200,
        );
      });
      await api.changePassword(
        currentPassword: 'old-password',
        newPassword: 'fifteenCharsPass',
      );
    });

    test('list sessions success', () async {
      useHandler((options) async {
        expect(options.path, equals('/api/v1/account/sessions'));
        return jsonBody(
          successEnvelope(<String, dynamic>{
            'sessions': [
              <String, dynamic>{
                'id': '507f1f77bcf86cd799439012',
                'created_at': '2026-08-25T12:00:00.000Z',
                'expires_at': '2026-09-25T12:00:00.000Z',
                'last_rotated_at': '2026-08-25T12:00:00.000Z',
                'is_current': true,
              },
            ],
          }),
          200,
        );
      });
      final sessions = await api.listSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first.isCurrent, isTrue);
    });

    test('revoke session success', () async {
      useHandler((options) async {
        expect(options.method, equals('DELETE'));
        expect(
          options.path,
          equals('/api/v1/account/sessions/507f1f77bcf86cd799439012'),
        );
        return jsonBody(
          successEnvelope(<String, bool>{'current_session_revoked': false}),
          200,
        );
      });
      final revokedCurrent = await api.revokeSession(
        '507f1f77bcf86cd799439012',
      );
      expect(revokedCurrent, isFalse);
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
    test('maps 403 email_not_verified', () => expectCode(403, 'email_not_verified'));
    test(
      'maps invalid_or_expired_account_action_token',
      () => expectCode(400, 'invalid_or_expired_account_action_token'),
    );
    test(
      'maps account_action_delivery_unavailable',
      () => expectCode(503, 'account_action_delivery_unavailable'),
    );
    test(
      'maps invalid_current_password',
      () => expectCode(401, 'invalid_current_password'),
    );
    test(
      'maps password_reuse_not_allowed',
      () => expectCode(409, 'password_reuse_not_allowed'),
    );
    test('maps session_not_found', () => expectCode(404, 'session_not_found'));
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
