import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_user_models.dart';

class AdminUserApi {
  AdminUserApi(this._dio);

  final Dio _dio;

  Future<AdminUserPage> list({
    String? role,
    String? status,
    String? email,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/users',
        queryParameters: <String, Object>{
          'role': ?role,
          'status': ?status,
          'email': ?email,
          'limit': ?limit,
          'after': ?after,
        },
      );
      final data = ApiEnvelope.requireData(response.data);
      final items = data['items'];
      final next = data['next_cursor'];
      if (items is! List) {
        throw const FormatException('Admin user page JSON is invalid.');
      }
      return AdminUserPage(
        items: [
          for (final item in items)
            if (item is Map)
              AdminUserSummary.fromJson(Map<String, dynamic>.from(item)),
        ],
        nextCursor: next is String ? next : null,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminUserDetail> get(String userId) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/admin/users/$userId');
      return AdminUserDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminUserDetail> suspend({
    required String userId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/users/$userId/suspend',
        data: <String, String>{'reason': reason},
      );
      return AdminUserDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminUserDetail> reactivate(String userId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/users/$userId/reactivate',
      );
      return AdminUserDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminUserDetail> deactivate({
    required String userId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/users/$userId/deactivate',
        data: <String, String>{'reason': reason},
      );
      return AdminUserDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final adminUserApiProvider = Provider<AdminUserApi>((ref) {
  return AdminUserApi(ref.watch(authenticatedDioProvider));
});
