import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_models.dart';

class ChatApi {
  ChatApi(this._dio);

  final Dio _dio;

  Future<ConversationDetail> createOrGetConversation(String bookingId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/conversations/booking/$bookingId',
      );
      return ConversationDetail.fromJson(
        _requireNested(ApiEnvelope.requireData(response.data), 'conversation'),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<List<ConversationSummary>> listConversations() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/conversations');
      return _items(
        ApiEnvelope.requireData(response.data),
        ConversationSummary.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<ConversationDetail> getConversation(String conversationId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/conversations/$conversationId',
      );
      return ConversationDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    String? before,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/conversations/$conversationId/messages',
        queryParameters: <String, Object>{
          'limit': ?limit,
          'before': ?before,
          'after': ?after,
        },
      );
      return _items(
        ApiEnvelope.requireData(response.data),
        ChatMessage.fromJson,
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String idempotencyKey,
    required String body,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/conversations/$conversationId/messages',
        data: <String, String>{'body': body},
        options: Options(
          headers: <String, String>{'Idempotency-Key': idempotencyKey},
        ),
      );
      return ChatMessage.fromJson(
        _requireNested(ApiEnvelope.requireData(response.data), 'message'),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<void> markRead(String conversationId, {String? messageId}) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/conversations/$conversationId/read',
        data: <String, Object?>{'message_id': ?messageId},
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

Map<String, dynamic> _requireNested(Map<String, dynamic> data, String key) {
  final nested = data[key];
  if (nested is! Map) {
    throw FormatException('Chat JSON field $key is invalid.');
  }
  return Map<String, dynamic>.from(nested);
}

List<T> _items<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic> json) parse,
) {
  final items = data['items'];
  if (items is! List) {
    throw const FormatException('Chat list JSON is invalid.');
  }
  return [
    for (final item in items)
      if (item is Map) parse(Map<String, dynamic>.from(item)),
  ];
}

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(authenticatedDioProvider));
});
