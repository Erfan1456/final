import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';

class CustomerReviewApi {
  CustomerReviewApi(this._dio);

  final Dio _dio;

  Future<CustomerReview?> getForBooking(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/customer/bookings/$bookingId/review',
      );
      final review = ApiEnvelope.requireData(response.data)['review'];
      if (review == null) {
        return null;
      }
      if (review is! Map) {
        throw const FormatException('Review JSON is invalid.');
      }
      return CustomerReview.fromJson(Map<String, dynamic>.from(review));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CustomerReview> upsertForBooking({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/customer/bookings/$bookingId/review',
        data: <String, Object?>{'rating': rating, 'comment': comment},
      );
      final review = ApiEnvelope.requireData(response.data)['review'];
      if (review is! Map) {
        throw const FormatException('Review JSON is invalid.');
      }
      return CustomerReview.fromJson(Map<String, dynamic>.from(review));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

class CleanerReviewApi {
  CleanerReviewApi(this._dio);

  final Dio _dio;

  Future<ReviewPage<CleanerReview>> list({
    String? status,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/reviews',
        queryParameters: <String, Object>{
          'status': ?status,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return _page(
        ApiEnvelope.requireData(response.data),
        CleanerReview.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

class AdminReviewApi {
  AdminReviewApi(this._dio);

  final Dio _dio;

  Future<ReviewPage<AdminReviewSummary>> list({
    String? status,
    int? rating,
    String? cleanerUserId,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/reviews',
        queryParameters: <String, Object>{
          'status': ?status,
          'rating': ?rating,
          'cleaner_user_id': ?cleanerUserId,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return _page(
        ApiEnvelope.requireData(response.data),
        AdminReviewSummary.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminReviewDetail> get(String reviewId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/reviews/$reviewId',
      );
      return AdminReviewDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminReviewDetail> hide({
    required String reviewId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/reviews/$reviewId/hide',
        data: <String, String>{'reason': reason},
      );
      return AdminReviewDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminReviewDetail> unhide(String reviewId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/reviews/$reviewId/unhide',
      );
      return AdminReviewDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

ReviewPage<T> _page<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic> json) parse,
) {
  final items = data['items'];
  final next = data['next_cursor'];
  if (items is! List) {
    throw const FormatException('Review page JSON is invalid.');
  }
  return ReviewPage(
    items: [
      for (final item in items)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ],
    nextCursor: next is String ? next : null,
  );
}

final customerReviewApiProvider = Provider<CustomerReviewApi>((ref) {
  return CustomerReviewApi(ref.watch(authenticatedDioProvider));
});

final cleanerReviewApiProvider = Provider<CleanerReviewApi>((ref) {
  return CleanerReviewApi(ref.watch(authenticatedDioProvider));
});

final adminReviewApiProvider = Provider<AdminReviewApi>((ref) {
  return AdminReviewApi(ref.watch(authenticatedDioProvider));
});
