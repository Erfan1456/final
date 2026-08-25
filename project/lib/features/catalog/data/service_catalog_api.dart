import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';

/// Public catalog API. Uses plain Dio without Bearer attachment.
class ServiceCatalogApi {
  ServiceCatalogApi(this._dio);

  final Dio _dio;

  Future<List<MarketplaceService>> listActive() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/services');
      final items = ApiEnvelope.requireData(response.data)['items'];
      if (items is! List) {
        throw const FormatException('Service catalog JSON is invalid.');
      }
      return [
        for (final item in items)
          if (item is Map)
            MarketplaceService.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final serviceCatalogApiProvider = Provider<ServiceCatalogApi>((ref) {
  return ServiceCatalogApi(ref.watch(plainDioProvider));
});
