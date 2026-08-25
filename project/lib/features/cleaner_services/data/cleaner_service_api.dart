import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_offering.dart';

/// Authenticated cleaner offering API.
class CleanerServiceApi {
  CleanerServiceApi(this._dio);

  final Dio _dio;

  Future<List<CleanerServiceOffering>> list() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/cleaner/services');
      final items = ApiEnvelope.requireData(response.data)['items'];
      if (items is! List) {
        throw const FormatException('Cleaner service list JSON is invalid.');
      }
      return [
        for (final item in items)
          if (item is Map)
            CleanerServiceOffering.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerServiceOffering> upsert({
    required String serviceId,
    required int hourlyRateMinor,
    required String currencyCode,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/cleaner/services/$serviceId',
        data: <String, Object>{
          'hourly_rate_minor': hourlyRateMinor,
          'currency_code': currencyCode,
          'is_active': isActive,
        },
      );
      return _requireOffering(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerServiceOffering> deactivate(String serviceId) async {
    try {
      final response = await _dio.delete<dynamic>(
        '/api/v1/cleaner/services/$serviceId',
      );
      return _requireOffering(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  CleanerServiceOffering _requireOffering(Map<String, dynamic> data) {
    final offering = data['offering'];
    if (offering is! Map) {
      throw const FormatException('Cleaner service offering JSON is invalid.');
    }
    return CleanerServiceOffering.fromJson(Map<String, dynamic>.from(offering));
  }
}

final cleanerServiceApiProvider = Provider<CleanerServiceApi>((ref) {
  return CleanerServiceApi(ref.watch(authenticatedDioProvider));
});
