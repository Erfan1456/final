import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';

/// Authenticated customer profile HTTP API.
class CustomerProfileApi {
  /// Creates an API over [authenticated] Dio.
  CustomerProfileApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/customer/profile. Returns `null` when absent.
  Future<CustomerProfile?> getProfile() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/customer/profile');
      final data = ApiEnvelope.requireData(response.data);
      final profile = data['profile'];
      if (profile == null) {
        return null;
      }
      if (profile is! Map) {
        throw const FormatException('Customer profile JSON is invalid.');
      }
      return CustomerProfile.fromJson(Map<String, dynamic>.from(profile));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// PUT /api/v1/customer/profile.
  Future<CustomerProfile> saveProfile({
    required String fullName,
    required String? phoneE164,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/customer/profile',
        data: <String, Object?>{'full_name': fullName, 'phone_e164': phoneE164},
      );
      final profile = ApiEnvelope.requireData(response.data)['profile'];
      if (profile is! Map) {
        throw const FormatException('Customer profile JSON is invalid.');
      }
      return CustomerProfile.fromJson(Map<String, dynamic>.from(profile));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

/// Customer profile API using authenticated Dio.
final customerProfileApiProvider = Provider<CustomerProfileApi>((ref) {
  return CustomerProfileApi(ref.watch(authenticatedDioProvider));
});
