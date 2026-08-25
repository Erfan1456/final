import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';

class BookingDisputeApi {
  BookingDisputeApi(this._dio);

  final Dio _dio;

  Future<BookingDispute?> getForBooking(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/bookings/$bookingId/dispute',
      );
      final dispute = ApiEnvelope.requireData(response.data)['dispute'];
      if (dispute == null) {
        return null;
      }
      if (dispute is! Map) {
        throw const FormatException('Dispute JSON is invalid.');
      }
      return BookingDispute.fromJson(Map<String, dynamic>.from(dispute));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<BookingDispute> create({
    required String bookingId,
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/bookings/$bookingId/dispute',
        data: <String, String>{
          'category': category,
          'subject': subject,
          'description': description,
        },
      );
      final dispute = ApiEnvelope.requireData(response.data)['dispute'];
      if (dispute is! Map) {
        throw const FormatException('Dispute JSON is invalid.');
      }
      return BookingDispute.fromJson(Map<String, dynamic>.from(dispute));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<BookingDispute> close(String bookingId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/bookings/$bookingId/dispute/close',
      );
      final dispute = ApiEnvelope.requireData(response.data)['dispute'];
      if (dispute is! Map) {
        throw const FormatException('Dispute JSON is invalid.');
      }
      return BookingDispute.fromJson(Map<String, dynamic>.from(dispute));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

class AdminDisputeApi {
  AdminDisputeApi(this._dio);

  final Dio _dio;

  Future<DisputePage<AdminDisputeSummary>> list({
    String? status,
    String? category,
    String? bookingId,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/disputes',
        queryParameters: <String, Object>{
          'status': ?status,
          'category': ?category,
          'booking_id': ?bookingId,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return _page(
        ApiEnvelope.requireData(response.data),
        AdminDisputeSummary.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminDisputeDetail> get(String disputeId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/disputes/$disputeId',
      );
      return AdminDisputeDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminDisputeDetail> markUnderReview(String disputeId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/disputes/$disputeId/review',
      );
      return AdminDisputeDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminDisputeDetail> resolve({
    required String disputeId,
    required String resolution,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/disputes/$disputeId/resolve',
        data: <String, String>{'resolution': resolution},
      );
      return AdminDisputeDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminDisputeDetail> close(String disputeId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/disputes/$disputeId/close',
      );
      return AdminDisputeDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

DisputePage<T> _page<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic> json) parse,
) {
  final items = data['items'];
  final next = data['next_cursor'];
  if (items is! List) {
    throw const FormatException('Dispute page JSON is invalid.');
  }
  return DisputePage(
    items: [
      for (final item in items)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ],
    nextCursor: next is String ? next : null,
  );
}

final bookingDisputeApiProvider = Provider<BookingDisputeApi>((ref) {
  return BookingDisputeApi(ref.watch(authenticatedDioProvider));
});

final adminDisputeApiProvider = Provider<AdminDisputeApi>((ref) {
  return AdminDisputeApi(ref.watch(authenticatedDioProvider));
});
