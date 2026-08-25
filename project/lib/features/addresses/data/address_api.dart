import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';

/// Authenticated address HTTP API.
class AddressApi {
  /// Creates an API over [authenticated] Dio.
  AddressApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/customer/addresses.
  Future<List<Address>> list() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/customer/addresses');
      final items = ApiEnvelope.requireData(response.data)['addresses'];
      if (items is! List) {
        throw const FormatException('Address list JSON is invalid.');
      }
      return [
        for (final item in items)
          if (item is Map) Address.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// POST /api/v1/customer/addresses.
  Future<Address> create(Map<String, Object?> body) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/customer/addresses',
        data: body,
      );
      return _requireAddress(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// PUT /api/v1/customer/addresses/{id}.
  Future<Address> update(String id, Map<String, Object?> body) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/customer/addresses/$id',
        data: body,
      );
      return _requireAddress(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// DELETE /api/v1/customer/addresses/{id}.
  Future<void> delete(String id) async {
    try {
      await _dio.delete<dynamic>('/api/v1/customer/addresses/$id');
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  /// PUT /api/v1/customer/addresses/{id}/default.
  Future<CustomerProfile> setDefault(String id) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/customer/addresses/$id/default',
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

  Address _requireAddress(Map<String, dynamic> data) {
    final address = data['address'];
    if (address is! Map) {
      throw const FormatException('Address JSON is invalid.');
    }
    return Address.fromJson(Map<String, dynamic>.from(address));
  }
}

/// Address API using authenticated Dio.
final addressApiProvider = Provider<AddressApi>((ref) {
  return AddressApi(ref.watch(authenticatedDioProvider));
});
