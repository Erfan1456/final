import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_models.dart';

class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  Future<NotificationPage> list({
    bool? unread,
    int? limit,
    String? after,
  }) async {
    try {
      final unreadQuery = unread == true ? 'true' : null;
      final response = await _dio.get<dynamic>(
        '/api/v1/notifications',
        queryParameters: <String, Object>{
          'unread': ?unreadQuery,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return NotificationPage.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/notifications/unread-count',
      );
      final data = ApiEnvelope.requireData(response.data);
      final count = data['unread_count'];
      if (count is! int) {
        throw const FormatException('Unread count JSON is invalid.');
      }
      return count;
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<InboxNotification> markRead(String notificationId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/notifications/$notificationId/read',
      );
      return InboxNotification.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<int> markAllRead() async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/notifications/read-all',
      );
      final data = ApiEnvelope.requireData(response.data);
      final count = data['unread_count'];
      if (count is! int) {
        throw const FormatException('Unread count JSON is invalid.');
      }
      return count;
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(authenticatedDioProvider));
});
