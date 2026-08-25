import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_api.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_models.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  test('parses conversation and message JSON', () {
    final conversation = ConversationDetail.fromJson(
      conversationJson(bookingStatus: 'in_progress'),
    );
    expect(conversation.bookingStatus, equals(BookingStatus.inProgress));
    expect(conversation.readOnly, isFalse);
    final message = ChatMessage.fromJson(chatMessageJson(isMine: false));
    expect(message.isMine, isFalse);
    expect(message.body, equals('Hello there'));
    expect(
      jsonEncode(chatMessageJson()),
      isNot(contains('client_idempotency_key')),
    );
  });

  test('closed booking statuses are read-only', () {
    expect(
      ConversationDetail.fromJson(conversationJson(bookingStatus: 'completed'))
          .readOnly,
      isTrue,
    );
    expect(
      ConversationDetail.fromJson(conversationJson(bookingStatus: 'declined'))
          .readOnly,
      isTrue,
    );
    expect(
      ConversationDetail.fromJson(conversationJson(bookingStatus: 'cancelled'))
          .readOnly,
      isTrue,
    );
  });

  test('sendMessage sends Idempotency-Key and body', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    final adapter = _Adapter((options) async {
      expect(options.headers['Idempotency-Key'], equals('idem-key-16charsx'));
      expect(options.data['body'], equals('Hello there'));
      expect(options.path, contains('/messages'));
      return jsonBody(
        successEnvelope(<String, dynamic>{'message': chatMessageJson()}),
        201,
      );
    });
    dio.httpClientAdapter = adapter;
    final message = await ChatApi(dio).sendMessage(
      conversationId: '507f1f77bcf86cd7994390a1',
      idempotencyKey: 'idem-key-16charsx',
      body: 'Hello there',
    );
    expect(message.id, equals('507f1f77bcf86cd7994390b1'));
  });

  test('getMessages sends pagination cursors', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.queryParameters['before'], equals('old-id'));
      expect(options.queryParameters['after'], equals('new-id'));
      expect(options.queryParameters['limit'], equals(20));
      return jsonBody(
        successEnvelope(<String, dynamic>{
          'items': [chatMessageJson()],
        }),
        200,
      );
    });
    final items = await ChatApi(dio).getMessages(
      '507f1f77bcf86cd7994390a1',
      limit: 20,
      before: 'old-id',
      after: 'new-id',
    );
    expect(items, hasLength(1));
  });

  test('createOrGet parses nested conversation', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      expect(options.path, contains('/conversations/booking/'));
      return jsonBody(
        successEnvelope(<String, dynamic>{'conversation': conversationJson()}),
        201,
      );
    });
    final conversation = await ChatApi(dio)
        .createOrGetConversation('507f1f77bcf86cd799439091');
    expect(conversation.otherPartyDisplayName, equals('Ada Cleaner'));
  });

  test('conversation_read_only maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'conversation_read_only', message: 'ignored'),
        409,
      );
    });
    await expectLater(
      ChatApi(dio).sendMessage(
        conversationId: '507f1f77bcf86cd7994390a1',
        idempotencyKey: 'idem-key-16charsx',
        body: 'Hello there',
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          contains('read-only'),
        ),
      ),
    );
  });

  test('conversation_not_found maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'conversation_not_found', message: 'ignored'),
        404,
      );
    });
    await expectLater(
      ChatApi(dio).getConversation('missing'),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'Conversation was not found.',
        ),
      ),
    );
  });
}
