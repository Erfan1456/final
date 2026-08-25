import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_interceptor.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/single_flight_refresher.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_api.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

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
  test('parses known statuses and unknown values safely', () {
    expect(PaymentStatus.fromWire('paid'), equals(PaymentStatus.paid));
    expect(
      PaymentStatus.fromWire('partially_refunded'),
      equals(PaymentStatus.partiallyRefunded),
    );
    expect(PaymentStatus.fromWire('stripe'), equals(PaymentStatus.unknown));
    expect(
      PaymentProviderType.fromWire('sandbox'),
      equals(PaymentProviderType.sandbox),
    );
    expect(
      PaymentProviderType.fromWire('stripe'),
      equals(PaymentProviderType.unknown),
    );
  });

  test('history parses current, attempts, and sandbox flag', () {
    final history = PaymentHistory.fromJson(<String, dynamic>{
      'current': paymentAttemptJson(simulationAvailable: true),
      'attempts': [paymentAttemptJson(simulationAvailable: true)],
    });
    expect(history.current?.status, equals(PaymentStatus.pending));
    expect(history.attempts, hasLength(1));
    expect(history.current?.simulationAvailable, isTrue);
    expect(history.current?.provider.label, equals('Development Sandbox'));
    expect(
      jsonEncode(paymentAttemptJson(simulationAvailable: true)),
      isNot(contains('client_idempotency_key')),
    );
  });

  test('idempotency key has at least 128 bits and no padding', () {
    final key = generateBookingIdempotencyKey();
    expect(key.length, greaterThanOrEqualTo(16));
    expect(key.length, lessThanOrEqualTo(128));
    expect(key.contains('='), isFalse);
  });

  test('startPayment sends Idempotency-Key', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final adapter = _Adapter((options) async {
      expect(options.headers['Idempotency-Key'], equals('idem-key-16charsx'));
      expect(options.path, contains('/payment'));
      return jsonBody(
        successEnvelope(<String, dynamic>{'payment': paymentAttemptJson()}),
        201,
      );
    });
    dio.httpClientAdapter = adapter;
    final payment = await CustomerPaymentApi(dio).startPayment(
      bookingId: '507f1f77bcf86cd799439091',
      idempotencyKey: 'idem-key-16charsx',
    );
    expect(payment.attemptNumber, equals(1));
    expect(payment.amountMinor, equals(500000));
  });

  test('auth refresh retry preserves Idempotency-Key', () async {
    final storage = InMemoryAuthTokenStorage()
      ..value = const AuthTokenPair(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
    final events = AuthSessionEventBus();
    final authenticated = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final adapter = _Adapter((options) async {
      if (options.headers['Authorization'] == 'Bearer new-access') {
        expect(options.headers['Idempotency-Key'], equals('idem-key-16charsx'));
        return jsonBody(
          successEnvelope(<String, dynamic>{'payment': paymentAttemptJson()}),
          201,
        );
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
          return const AuthTokenPair(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          );
        },
      ),
    );
    await CustomerPaymentApi(authenticated).startPayment(
      bookingId: '507f1f77bcf86cd799439091',
      idempotencyKey: 'idem-key-16charsx',
    );
    expect(adapter.requests, hasLength(2));
    expect(
      adapter.requests.every(
        (request) => request.headers['Idempotency-Key'] == 'idem-key-16charsx',
      ),
      isTrue,
    );
    events.dispose();
  });

  test('booking_not_payable maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'booking_not_payable', message: 'ignored'),
        409,
      );
    });
    await expectLater(
      CustomerPaymentApi(dio).startPayment(
        bookingId: '507f1f77bcf86cd799439091',
        idempotencyKey: 'idem-key-16charsx',
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'This booking cannot be paid until it is confirmed.',
        ),
      ),
    );
  });

  test('admin refund sends Idempotency-Key', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.headers['Idempotency-Key'], equals('refund-idem-key-16x'));
      expect(options.data['reason'], equals('Customer requested a refund.'));
      return jsonBody(
        successEnvelope(<String, dynamic>{
          'payment': adminPaymentJson(),
          'events': [webhookEventJson()],
        }),
        200,
      );
    });
    final detail = await AdminPaymentApi(dio).refund(
      paymentId: '507f1f77bcf86cd7994390d1',
      idempotencyKey: 'refund-idem-key-16x',
      reason: 'Customer requested a refund.',
    );
    expect(detail.status, equals(PaymentStatus.paid));
    expect(detail.events, hasLength(1));
  });
}
