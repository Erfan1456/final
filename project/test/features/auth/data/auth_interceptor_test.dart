import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_interceptor.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/single_flight_refresher.dart';

import '../../../helpers/auth_test_fakes.dart';

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
  late List<AuthSessionEvent> emitted;
  late int refreshCalls;
  late List<String> refreshTokens;
  late Dio dio;
  late _Adapter adapter;
  late SingleFlightRefresher refresher;

  setUp(() {
    storage = InMemoryAuthTokenStorage();
    events = AuthSessionEventBus();
    emitted = <AuthSessionEvent>[];
    events.stream.listen(emitted.add);
    refreshCalls = 0;
    refreshTokens = <String>[];
    refresher = SingleFlightRefresher();
    dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    adapter = _Adapter((options) async => jsonBody(<String, String>{}, 200));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        events: events,
        dio: dio,
        refresher: refresher,
        refreshTokens: (token) async {
          refreshCalls += 1;
          refreshTokens.add(token);
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

  test('attaches Bearer token to protected requests', () async {
    storage.value = const AuthTokenPair(
      accessToken: 'stored-access',
      refreshToken: 'stored-refresh',
    );
    adapter.handler = (options) async {
      expect(options.headers['Authorization'], equals('Bearer stored-access'));
      return jsonBody(successEnvelope(<String, dynamic>{'ok': true}), 200);
    };

    await dio.get<dynamic>('/api/v1/account/me');
  });

  test('does not attach Authorization when no token exists', () async {
    adapter.handler = (options) async {
      expect(options.headers.containsKey('Authorization'), isFalse);
      return jsonBody(successEnvelope(<String, dynamic>{'ok': true}), 200);
    };

    await dio.get<dynamic>('/api/v1/account/me');
    expect(refreshCalls, equals(0));
  });

  test(
    'one 401 refreshes once, stores rotation, and retries with new token',
    () async {
      storage.value = const AuthTokenPair(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      var meCalls = 0;
      adapter.handler = (options) async {
        meCalls += 1;
        if (options.headers['Authorization'] == 'Bearer new-access') {
          return jsonBody(
            successEnvelope(<String, dynamic>{'user': userJson(testUser())}),
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

      final response = await dio.get<dynamic>('/api/v1/account/me');

      expect(response.statusCode, equals(200));
      expect(refreshCalls, equals(1));
      expect(refreshTokens, equals(['old-refresh']));
      expect(storage.value?.accessToken, equals('new-access'));
      expect(storage.value?.refreshToken, equals('new-refresh'));
      expect(meCalls, equals(2));
      expect(
        adapter.requests.last.headers['Authorization'],
        equals('Bearer new-access'),
      );
      expect(
        adapter.requests.last.extra[AuthInterceptor.retryExtraKey],
        isTrue,
      );
    },
  );

  test('failed refresh clears tokens and emits sessionExpired once', () async {
    storage.value = const AuthTokenPair(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    dio.interceptors.clear();
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        events: events,
        dio: dio,
        refresher: refresher,
        refreshTokens: (token) async {
          refreshCalls += 1;
          throw Exception('refresh failed');
        },
      ),
    );
    adapter.handler = (options) async {
      return jsonBody(
        errorEnvelope(
          code: 'invalid_access_token',
          message: 'Authentication is required.',
        ),
        401,
      );
    };

    await expectLater(
      dio.get<dynamic>('/api/v1/account/me'),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, equals(1));
    expect(storage.value, isNull);
    expect(storage.clearCount, equals(1));
    expect(emitted, equals([AuthSessionEvent.expired]));
  });

  test('retry marker prevents an infinite refresh loop', () async {
    storage.value = const AuthTokenPair(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    adapter.handler = (options) async {
      return jsonBody(
        errorEnvelope(
          code: 'invalid_access_token',
          message: 'Authentication is required.',
        ),
        401,
      );
    };

    await expectLater(
      dio.get<dynamic>('/api/v1/account/me'),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, equals(1));
  });

  test('refresh endpoint never recursively refreshes', () async {
    storage.value = const AuthTokenPair(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    adapter.handler = (options) async {
      return jsonBody(
        errorEnvelope(
          code: 'invalid_refresh_token',
          message: 'Refresh token is invalid or expired.',
        ),
        401,
      );
    };

    await expectLater(
      dio.post<dynamic>('/api/v1/auth/refresh'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, equals(0));
  });

  test(
    'concurrent protected 401s share one refresh and retry after it',
    () async {
      storage.value = const AuthTokenPair(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      final gate = Completer<void>();
      dio.interceptors.clear();
      dio.interceptors.add(
        AuthInterceptor(
          storage: storage,
          events: events,
          dio: dio,
          refresher: refresher,
          refreshTokens: (token) async {
            refreshCalls += 1;
            await gate.future;
            return const AuthTokenPair(
              accessToken: 'new-access',
              refreshToken: 'new-refresh',
            );
          },
        ),
      );
      adapter.handler = (options) async {
        if (options.headers['Authorization'] == 'Bearer new-access') {
          return jsonBody(successEnvelope(<String, dynamic>{'ok': true}), 200);
        }
        return jsonBody(
          errorEnvelope(
            code: 'invalid_access_token',
            message: 'Authentication is required.',
          ),
          401,
        );
      };

      final futures = List<Future<Response<dynamic>>>.generate(
        5,
        (_) => dio.get<dynamic>('/api/v1/account/me'),
      );
      await pumpEventQueue();
      expect(refreshCalls, equals(1));
      gate.complete();
      final results = await Future.wait(futures);

      expect(results.every((response) => response.statusCode == 200), isTrue);
      expect(refreshCalls, equals(1));
      expect(storage.value?.accessToken, equals('new-access'));
    },
  );

  test('concurrent refresh failure clears the session once', () async {
    storage.value = const AuthTokenPair(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final gate = Completer<void>();
    dio.interceptors.clear();
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        events: events,
        dio: dio,
        refresher: refresher,
        refreshTokens: (token) async {
          refreshCalls += 1;
          await gate.future;
          throw Exception('refresh failed');
        },
      ),
    );
    adapter.handler = (options) async {
      return jsonBody(
        errorEnvelope(
          code: 'invalid_access_token',
          message: 'Authentication is required.',
        ),
        401,
      );
    };

    final futures = List<Future<Response<dynamic>>>.generate(
      5,
      (_) => dio.get<dynamic>('/api/v1/account/me'),
    );
    await pumpEventQueue();
    gate.complete();
    await Future.wait(
      futures.map(
        (future) => expectLater(future, throwsA(isA<DioException>())),
      ),
    );

    expect(refreshCalls, equals(1));
    expect(storage.value, isNull);
    expect(storage.clearCount, equals(1));
    expect(emitted, equals([AuthSessionEvent.expired]));
  });
}
