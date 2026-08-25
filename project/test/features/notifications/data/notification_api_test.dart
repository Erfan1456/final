import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_api.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_models.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
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
  test('unknown notification type does not crash', () {
    final notification = InboxNotification.fromJson(
      inboxNotificationJson(type: 'future_event'),
    );
    expect(notification.type, equals(NotificationType.unknown));
  });

  test('parses list, omits dedupe_key, and unread count', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      if (options.path.endsWith('/unread-count')) {
        return jsonBody(
          successEnvelope(<String, dynamic>{'unread_count': 2}),
          200,
        );
      }
      expect(options.queryParameters['unread'], equals('true'));
      expect(options.queryParameters['after'], equals('cursor-1'));
      return jsonBody(
        successEnvelope(<String, dynamic>{
          'items': [inboxNotificationJson()],
          'next_cursor': 'next',
        }),
        200,
      );
    });
    final api = NotificationApi(dio);
    final page = await api.list(unread: true, after: 'cursor-1');
    expect(page.items, hasLength(1));
    expect(page.nextCursor, equals('next'));
    expect(jsonEncode(inboxNotificationJson()), isNot(contains('dedupe_key')));
    expect(await api.unreadCount(), equals(2));
  });

  test('notification_not_found maps to a safe ApiFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return jsonBody(
        errorEnvelope(code: 'notification_not_found', message: 'ignored'),
        404,
      );
    });
    await expectLater(
      NotificationApi(dio).markRead('missing'),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'Notification was not found.',
        ),
      ),
    );
  });
}
