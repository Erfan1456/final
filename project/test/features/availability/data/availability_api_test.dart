import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_interceptor.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/single_flight_refresher.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_api.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/service_catalog_api.dart';

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
  test('public catalog uses the supplied Dio without requiring auth', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final adapter = _Adapter((options) async {
      expect(options.headers.containsKey('Authorization'), isFalse);
      return jsonBody(
        successEnvelope(<String, dynamic>{
          'items': [
            <String, dynamic>{
              'id': 's1',
              'slug': 'home-cleaning',
              'name': 'Home Cleaning',
              'description': 'Hourly professional cleaning.',
              'billing_model': 'hourly',
            },
          ],
        }),
        200,
      );
    });
    dio.httpClientAdapter = adapter;
    final items = await ServiceCatalogApi(dio).listActive();
    expect(items.single.slug, equals('home-cleaning'));
  });

  test('protected availability API uses the existing refresh path', () async {
    final storage = InMemoryAuthTokenStorage()
      ..value = const AuthTokenPair(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
    final events = AuthSessionEventBus();
    var refreshCalls = 0;
    final authenticated = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final adapter = _Adapter((options) async {
      if (options.headers['Authorization'] == 'Bearer new-access') {
        return jsonBody(successEnvelope(<String, dynamic>{'items': []}), 200);
      }
      return jsonBody(
        errorEnvelope(
          code: 'invalid_access_token',
          message: 'Authentication is required.',
        ),
        401,
      );
    });
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

    final items = await AvailabilityApi(authenticated).list();
    expect(items, isEmpty);
    expect(refreshCalls, equals(1));
    expect(storage.value?.accessToken, equals('new-access'));
    events.dispose();
  });

  test('availability overlap maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'availability_overlap', message: 'ignored'),
        409,
      );
    });
    await expectLater(
      AvailabilityApi(dio).create(
        serviceId: 's1',
        startAt: '2026-09-01T03:00:00.000Z',
        endAt: '2026-09-01T05:00:00.000Z',
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'This availability window overlaps another slot.',
        ),
      ),
    );
  });
}
