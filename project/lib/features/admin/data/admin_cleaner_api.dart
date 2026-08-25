import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

/// Authenticated admin cleaner-review HTTP API.
class AdminCleanerApi {
  /// Creates an API over [authenticated] Dio.
  AdminCleanerApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/cleaners.
  Future<AdminCleanerApplicationPage> list({
    String? status,
    String? after,
    int? limit,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/cleaners',
        queryParameters: <String, Object>{
          'status': ?status,
          'after': ?after,
          'limit': ?limit,
        },
      );
      return AdminCleanerApplicationPage.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// GET /api/v1/admin/cleaners/{userId}.
  Future<AdminCleanerApplicationDetail> get(String userId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/cleaners/$userId',
      );
      return AdminCleanerApplicationDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// POST /api/v1/admin/cleaners/{userId}/approve.
  Future<CleanerProfile> approve(String userId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/cleaners/$userId/approve',
      );
      return _requireProfile(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// POST /api/v1/admin/cleaners/{userId}/reject.
  Future<CleanerProfile> reject(String userId, String reason) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/cleaners/$userId/reject',
        data: <String, String>{'reason': reason},
      );
      return _requireProfile(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  CleanerProfile _requireProfile(Map<String, dynamic> data) {
    final profile = data['profile'];
    if (profile is! Map) {
      throw const FormatException('Cleaner profile JSON is invalid.');
    }
    return CleanerProfile.fromJson(Map<String, dynamic>.from(profile));
  }
}

/// Admin API using authenticated Dio.
final adminCleanerApiProvider = Provider<AdminCleanerApi>((ref) {
  return AdminCleanerApi(ref.watch(authenticatedDioProvider));
});
