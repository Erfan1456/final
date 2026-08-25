import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';

/// Authenticated customer discovery API.
class DiscoveryApi {
  DiscoveryApi(this._dio);

  final Dio _dio;

  Future<CleanerDiscoveryPage> listCleaners({
    String? service,
    String? currency,
    int? maxRateMinor,
    int? minExperience,
    String? availableFrom,
    String? availableTo,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/discovery/cleaners',
        queryParameters: <String, Object>{
          'service': ?service,
          'currency': ?currency,
          'max_rate_minor': ?maxRateMinor,
          'min_experience': ?minExperience,
          'available_from': ?availableFrom,
          'available_to': ?availableTo,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return CleanerDiscoveryPage.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerDiscoveryDetail> getCleanerDetail({
    required String cleanerUserId,
    String? service,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/discovery/cleaners/$cleanerUserId',
        queryParameters: <String, Object>{'service': ?service},
      );
      return CleanerDiscoveryDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final discoveryApiProvider = Provider<DiscoveryApi>((ref) {
  return DiscoveryApi(ref.watch(authenticatedDioProvider));
});
