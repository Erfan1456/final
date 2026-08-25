import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';

class CustomerBookingApi {
  CustomerBookingApi(this._dio);

  final Dio _dio;

  Future<CustomerBooking> createBooking({
    required String availabilitySlotId,
    required String addressId,
    required String idempotencyKey,
    String? customerNotes,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/customer/bookings',
        data: <String, Object?>{
          'availability_slot_id': availabilitySlotId,
          'address_id': addressId,
          'customer_notes': customerNotes,
        },
        options: Options(
          headers: <String, String>{'Idempotency-Key': idempotencyKey},
        ),
      );
      return CustomerBooking.fromJson(
        _requireBooking(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<BookingPage<CustomerBooking>> listBookings({
    String? status,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/customer/bookings',
        queryParameters: <String, Object>{
          'status': ?status,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return _page(
        ApiEnvelope.requireData(response.data),
        CustomerBooking.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CustomerBooking> getBooking(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/customer/bookings/$bookingId',
      );
      return CustomerBooking.fromJson(
        _requireBooking(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CustomerBooking> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/customer/bookings/$bookingId/cancel',
        data: <String, Object?>{'reason': reason},
      );
      return CustomerBooking.fromJson(
        _requireBooking(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

class CleanerBookingApi {
  CleanerBookingApi(this._dio);

  final Dio _dio;

  Future<BookingPage<CleanerBooking>> listBookings({
    String? status,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/bookings',
        queryParameters: <String, Object>{
          'status': ?status,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return _page(
        ApiEnvelope.requireData(response.data),
        CleanerBooking.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerBooking> getBooking(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/bookings/$bookingId',
      );
      return CleanerBooking.fromJson(
        _requireBooking(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerBooking> accept(String bookingId) {
    return _mutate('/api/v1/cleaner/bookings/$bookingId/accept');
  }

  Future<CleanerBooking> decline(String bookingId, {required String reason}) {
    return _mutate(
      '/api/v1/cleaner/bookings/$bookingId/decline',
      body: <String, Object?>{'reason': reason},
    );
  }

  Future<CleanerBooking> cancel(String bookingId, {required String reason}) {
    return _mutate(
      '/api/v1/cleaner/bookings/$bookingId/cancel',
      body: <String, Object?>{'reason': reason},
    );
  }

  Future<CleanerBooking> start(String bookingId) {
    return _mutate('/api/v1/cleaner/bookings/$bookingId/start');
  }

  Future<CleanerBooking> complete(String bookingId) {
    return _mutate('/api/v1/cleaner/bookings/$bookingId/complete');
  }

  Future<CleanerBooking> _mutate(
    String path, {
    Map<String, Object?>? body,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      return CleanerBooking.fromJson(
        _requireBooking(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

Map<String, dynamic> _requireBooking(Map<String, dynamic> data) {
  final booking = data['booking'];
  if (booking is! Map) {
    throw const FormatException('Booking JSON is invalid.');
  }
  return Map<String, dynamic>.from(booking);
}

BookingPage<T> _page<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic> json) parse,
) {
  final items = data['items'];
  final next = data['next_cursor'];
  if (items is! List) {
    throw const FormatException('Booking page JSON is invalid.');
  }
  return BookingPage<T>(
    items: [
      for (final item in items)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ],
    nextCursor: next is String ? next : null,
  );
}

final customerBookingApiProvider = Provider<CustomerBookingApi>((ref) {
  return CustomerBookingApi(ref.watch(authenticatedDioProvider));
});

final cleanerBookingApiProvider = Provider<CleanerBookingApi>((ref) {
  return CleanerBookingApi(ref.watch(authenticatedDioProvider));
});
