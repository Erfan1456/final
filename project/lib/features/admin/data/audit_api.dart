import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/admin/data/audit_models.dart';

class AdminAuditApi {
  AdminAuditApi(this._dio);

  final Dio _dio;

  Future<AdminAuditLogPage> list({
    String? actorUserId,
    String? action,
    String? targetType,
    String? targetId,
    String? from,
    String? to,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/audit-logs',
        queryParameters: <String, Object>{
          'actor_user_id': ?actorUserId,
          'action': ?action,
          'target_type': ?targetType,
          'target_id': ?targetId,
          'from': ?from,
          'to': ?to,
          'limit': ?limit,
          'after': ?after,
        },
      );
      final data = ApiEnvelope.requireData(response.data);
      final items = data['items'];
      final next = data['next_cursor'];
      if (items is! List) {
        throw const FormatException('Audit log page JSON is invalid.');
      }
      return AdminAuditLogPage(
        items: [
          for (final item in items)
            if (item is Map)
              AdminAuditLogSummary.fromJson(Map<String, dynamic>.from(item)),
        ],
        nextCursor: next is String ? next : null,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminAuditLogDetail> get(String auditLogId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/audit-logs/$auditLogId',
      );
      return AdminAuditLogSummary.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final adminAuditApiProvider = Provider<AdminAuditApi>((ref) {
  return AdminAuditApi(ref.watch(authenticatedDioProvider));
});
