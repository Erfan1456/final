import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';

/// Authenticated cleaner availability API.
class AvailabilityApi {
  AvailabilityApi(this._dio);

  final Dio _dio;

  Future<List<AvailabilitySlot>> list({
    String? from,
    String? to,
    String? serviceId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/availability',
        queryParameters: <String, Object>{
          'from': ?from,
          'to': ?to,
          'service_id': ?serviceId,
        },
      );
      final items = ApiEnvelope.requireData(response.data)['items'];
      if (items is! List) {
        throw const FormatException('Availability list JSON is invalid.');
      }
      return [
        for (final item in items)
          if (item is Map)
            AvailabilitySlot.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AvailabilitySlot> create({
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/cleaner/availability',
        data: <String, String>{
          'service_id': serviceId,
          'start_at': startAt,
          'end_at': endAt,
        },
      );
      return _requireSlot(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AvailabilitySlot> get(String slotId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/availability/$slotId',
      );
      return _requireSlot(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AvailabilitySlot> update({
    required String slotId,
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/cleaner/availability/$slotId',
        data: <String, String>{
          'service_id': serviceId,
          'start_at': startAt,
          'end_at': endAt,
        },
      );
      return _requireSlot(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<void> delete(String slotId) async {
    try {
      await _dio.delete<dynamic>('/api/v1/cleaner/availability/$slotId');
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  AvailabilitySlot _requireSlot(Map<String, dynamic> data) {
    final slot = data['slot'];
    if (slot is! Map) {
      throw const FormatException('Availability slot JSON is invalid.');
    }
    return AvailabilitySlot.fromJson(Map<String, dynamic>.from(slot));
  }
}

final availabilityApiProvider = Provider<AvailabilityApi>((ref) {
  return AvailabilityApi(ref.watch(authenticatedDioProvider));
});
