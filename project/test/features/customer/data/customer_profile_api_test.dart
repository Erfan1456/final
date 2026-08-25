import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_interceptor.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/single_flight_refresher.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile_api.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
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
  late InMemoryAuthTokenStorage storage;
  late AuthSessionEventBus events;
  late Dio authenticated;
  late _Adapter adapter;
  late int refreshCalls;

  setUp(() {
    storage = InMemoryAuthTokenStorage();
    events = AuthSessionEventBus();
    refreshCalls = 0;
    authenticated = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    adapter = _Adapter((options) async => jsonBody(<String, String>{}, 200));
    authenticated.httpClientAdapter = adapter;
    authenticated.interceptors.add(
      AuthInterceptor(
        storage: storage,
        events: events,
        dio: authenticated,
        refresher: SingleFlightRefresher(),
        refreshTokens: (token) async {
          refreshCalls += 1;
          return const AuthTokenPair(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          );
        },
      ),
    );
  });

  tearDown(() {
    events.dispose();
  });

  test('customer profile GET parses a null profile', () async {
    adapter.handler = (options) async {
      return jsonBody(successEnvelope(<String, dynamic>{'profile': null}), 200);
    };
    final api = CustomerProfileApi(authenticated);
    expect(await api.getProfile(), isNull);
  });

  test('customer profile GET parses an existing profile', () async {
    adapter.handler = (options) async {
      return jsonBody(
        successEnvelope(<String, dynamic>{'profile': customerProfileJson()}),
        200,
      );
    };
    final profile = await CustomerProfileApi(authenticated).getProfile();
    expect(profile?.fullName, equals('Test Customer'));
  });

  test(
    'protected customer profile API refreshes once via authenticated Dio',
    () async {
      storage.value = const AuthTokenPair(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      adapter.handler = (options) async {
        if (options.headers['Authorization'] == 'Bearer new-access') {
          return jsonBody(
            successEnvelope(<String, dynamic>{
              'profile': customerProfileJson(),
            }),
            200,
          );
        }
        return jsonBody(
          errorEnvelope(
            code: 'invalid_access_token',
            message: 'Authentication is required.',
          ),
          401,
        );
      };

      final profile = await CustomerProfileApi(authenticated).getProfile();

      expect(profile?.fullName, equals('Test Customer'));
      expect(refreshCalls, equals(1));
      expect(storage.value?.accessToken, equals('new-access'));
      expect(adapter.requests.first.path, equals('/api/v1/customer/profile'));
      expect(
        adapter.requests.last.headers['Authorization'],
        equals('Bearer new-access'),
      );
    },
  );

  test('plain Dio does not refresh a protected customer profile 401', () async {
    final plain = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final plainAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(
          code: 'invalid_access_token',
          message: 'Authentication is required.',
        ),
        401,
      );
    });
    plain.httpClientAdapter = plainAdapter;

    await expectLater(
      CustomerProfileApi(plain).getProfile(),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'invalid_access_token',
        ),
      ),
    );
    expect(refreshCalls, equals(0));
    expect(plainAdapter.requests, hasLength(1));
  });

  test(
    'address API maps address_limit_reached without DioException text',
    () async {
      adapter.handler = (options) async {
        return jsonBody(
          errorEnvelope(
            code: 'address_limit_reached',
            message: 'You can save at most 20 addresses.',
          ),
          409,
        );
      };

      await expectLater(
        AddressApi(authenticated).create(<String, Object?>{'label': 'Home'}),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.message,
            'message',
            'You can save at most 20 addresses.',
          ),
        ),
      );
    },
  );

  test('address_not_found becomes a safe ApiFailure', () async {
    adapter.handler = (options) async {
      return jsonBody(
        errorEnvelope(code: 'address_not_found', message: 'missing'),
        404,
      );
    };

    await expectLater(
      AddressApi(authenticated).update('missing-id', <String, Object?>{}),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'address_not_found',
        ),
      ),
    );
  });

  test('ApiEnvelope maps forbidden without leaking internals', () {
    final failure = ApiEnvelope.mapDioException(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/profile'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/customer/profile'),
          statusCode: 403,
          data: errorEnvelope(
            code: 'forbidden',
            message: 'internal role table dump',
          ),
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(failure.code, equals('forbidden'));
    expect(
      failure.message,
      equals('You do not have permission to perform this action.'),
    );
  });
}
