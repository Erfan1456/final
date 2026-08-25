import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_interceptor.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/single_flight_refresher.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_api.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';

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
  test('customer booking parses status, history, and full address', () {
    final booking = CustomerBooking.fromJson(customerBookingJson());
    expect(booking.status, equals(BookingStatus.pending));
    expect(booking.cleanerFullName, equals('Ada Cleaner'));
    expect(booking.addressSnapshot.line1, equals('1 Test Street'));
    expect(
      booking.statusHistory.single.toStatus,
      equals(BookingStatus.pending),
    );
    expect(booking.quotedTotalMinor, equals(500000));
    expect(
      formatQuotedTotal(booking.quotedTotalMinor, booking.currencyCode),
      equals('Quoted total: BDT 500000 minor units'),
    );
  });

  test('cleaner pending booking keeps coarse address only', () {
    final booking = CleanerBooking.fromJson(cleanerBookingJson());
    expect(booking.customerDisplayName, equals('Test Customer'));
    expect(booking.addressSnapshot.line1, isNull);
    expect(booking.addressSnapshot.postalCode, isNull);
    expect(booking.addressSnapshot.isFull, isFalse);
    expect(booking.addressSnapshot.coarseSummary, contains('Dhaka'));
  });

  test('cleaner confirmed booking parses the supplied full address', () {
    final booking = CleanerBooking.fromJson(
      cleanerBookingJson(status: 'confirmed', fullAddress: true),
    );
    expect(booking.status, equals(BookingStatus.confirmed));
    expect(booking.addressSnapshot.line1, equals('1 Test Street'));
    expect(booking.addressSnapshot.label, equals('Home'));
  });

  test('quoted total preview uses integer round-half-up', () {
    expect(
      quotedTotalMinorPreview(hourlyRateMinor: 250000, durationMinutes: 120),
      equals(500000),
    );
    expect(
      quotedTotalMinorPreview(hourlyRateMinor: 1, durationMinutes: 30),
      equals(1),
    );
  });

  test('idempotency key has at least 128 bits and no padding', () {
    final key = generateBookingIdempotencyKey();
    expect(key.length, greaterThanOrEqualTo(16));
    expect(key.length, lessThanOrEqualTo(128));
    expect(key.contains('='), isFalse);
  });

  test('createBooking sends Idempotency-Key', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final adapter = _Adapter((options) async {
      expect(options.headers['Idempotency-Key'], equals('idem-key-16charsx'));
      expect(options.data['availability_slot_id'], equals('slot-1'));
      return jsonBody(
        successEnvelope(<String, dynamic>{'booking': customerBookingJson()}),
        201,
      );
    });
    dio.httpClientAdapter = adapter;
    final booking = await CustomerBookingApi(dio).createBooking(
      availabilitySlotId: 'slot-1',
      addressId: 'addr-1',
      idempotencyKey: 'idem-key-16charsx',
    );
    expect(booking.id, equals('507f1f77bcf86cd799439091'));
    expect(booking.idempotentReplay, isFalse);
  });

  test('identical replay parses idempotent_replay', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        successEnvelope(<String, dynamic>{
          'booking': customerBookingJson(idempotentReplay: true),
        }),
        200,
      );
    });
    final booking = await CustomerBookingApi(dio).createBooking(
      availabilitySlotId: 'slot-1',
      addressId: 'addr-1',
      idempotencyKey: 'idem-key-16charsx',
    );
    expect(booking.idempotentReplay, isTrue);
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
          successEnvelope(<String, dynamic>{'booking': customerBookingJson()}),
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

    await CustomerBookingApi(authenticated).createBooking(
      availabilitySlotId: 'slot-1',
      addressId: 'addr-1',
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

  test('availability_unavailable maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'availability_unavailable', message: 'ignored'),
        409,
      );
    });
    await expectLater(
      CustomerBookingApi(dio).createBooking(
        availabilitySlotId: 'slot-1',
        addressId: 'addr-1',
        idempotencyKey: 'idem-key-16charsx',
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'That time slot is no longer available.',
        ),
      ),
    );
  });

  test('cleaner API maps invalid_booking_state safely', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'invalid_booking_state', message: 'ignored'),
        409,
      );
    });
    await expectLater(
      CleanerBookingApi(dio).accept('booking-1'),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'This booking cannot be changed in its current state.',
        ),
      ),
    );
  });
}
