import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

/// Authenticated cleaner onboarding HTTP API.
class CleanerProfileApi {
  /// Creates an API over [authenticated] Dio.
  CleanerProfileApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/cleaner/profile.
  Future<CleanerProfile?> getProfile() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/cleaner/profile');
      final profile = ApiEnvelope.requireData(response.data)['profile'];
      if (profile == null) {
        return null;
      }
      if (profile is! Map) {
        throw const FormatException('Cleaner profile JSON is invalid.');
      }
      return CleanerProfile.fromJson(Map<String, dynamic>.from(profile));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// PUT /api/v1/cleaner/profile.
  Future<CleanerProfile> saveProfile(Map<String, Object?> body) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/cleaner/profile',
        data: body,
      );
      return _requireProfile(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// POST /api/v1/cleaner/onboarding/submit.
  Future<CleanerProfile> submit() async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/cleaner/onboarding/submit',
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

/// Cleaner API using authenticated Dio.
final cleanerProfileApiProvider = Provider<CleanerProfileApi>((ref) {
  return CleanerProfileApi(ref.watch(authenticatedDioProvider));
});
