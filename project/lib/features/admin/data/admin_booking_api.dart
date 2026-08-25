import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_booking_models.dart';

class AdminBookingApi {
  AdminBookingApi(this._dio);

  final Dio _dio;

  Future<AdminBookingPage> list({
    String? status,
    String? customerUserId,
    String? cleanerUserId,
    String? from,
    String? to,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/bookings',
        queryParameters: <String, Object>{
          'status': ?status,
          'customer_user_id': ?customerUserId,
          'cleaner_user_id': ?cleanerUserId,
          'from': ?from,
          'to': ?to,
          'limit': ?limit,
          'after': ?after,
        },
      );
      final data = ApiEnvelope.requireData(response.data);
      final items = data['items'];
      final next = data['next_cursor'];
      if (items is! List) {
        throw const FormatException('Admin booking page JSON is invalid.');
      }
      return AdminBookingPage(
        items: [
          for (final item in items)
            if (item is Map)
              AdminBookingSummary.fromJson(Map<String, dynamic>.from(item)),
        ],
        nextCursor: next is String ? next : null,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminBookingDetail> get(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/bookings/$bookingId',
      );
      return AdminBookingDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminBookingDetail> cancel({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/bookings/$bookingId/cancel',
        data: <String, String>{'reason': reason},
      );
      return AdminBookingDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final adminBookingApiProvider = Provider<AdminBookingApi>((ref) {
  return AdminBookingApi(ref.watch(authenticatedDioProvider));
});
