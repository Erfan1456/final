import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_api.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_models.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _FakeNotificationApi extends NotificationApi {
  _FakeNotificationApi() : super(Dio());

  NotificationPage page = NotificationPage(
    items: [testInboxNotification()],
    nextCursor: 'cursor-1',
  );
  NotificationPage more = const NotificationPage(items: []);
  int unread = 2;
  ApiFailure? nextError;
  int listCalls = 0;
  int moreCalls = 0;
  int markOneCalls = 0;
  int markAllCalls = 0;
  int unreadCalls = 0;
  String? lastAfter;
  bool? lastUnread;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<NotificationPage> list({
    bool? unread,
    int? limit,
    String? after,
  }) async {
    lastUnread = unread;
    lastAfter = after;
    if (after != null) {
      moreCalls += 1;
      _throwIfNeeded();
      return more;
    }
    listCalls += 1;
    _throwIfNeeded();
    return page;
  }

  @override
  Future<int> unreadCount() async {
    unreadCalls += 1;
    _throwIfNeeded();
    return unread;
  }

  @override
  Future<InboxNotification> markRead(String notificationId) async {
    markOneCalls += 1;
    _throwIfNeeded();
    unread = unread > 0 ? unread - 1 : 0;
    return testInboxNotification(
      id: notificationId,
      readAt: '2026-08-25T12:30:00.000Z',
    );
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls += 1;
    _throwIfNeeded();
    unread = 0;
    return 0;
  }
}

void main() {
  late _FakeNotificationApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeNotificationApi();
    container = ProviderContainer(
      overrides: [
        ...authenticatedAuthOverrides(),
        notificationApiProvider.overrideWithValue(api),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('load stores items and unread count', () async {
    await container.read(notificationControllerProvider.notifier).load();
    expect(container.read(notificationControllerProvider).items, hasLength(1));
    expect(
      container.read(notificationControllerProvider).unreadCount,
      equals(2),
    );
    expect(api.listCalls, equals(1));
  });

  test('markOne keeps list and count coherent', () async {
    final notifier = container.read(notificationControllerProvider.notifier);
    await notifier.load();
    await notifier.markOne('507f1f77bcf86cd7994390c1');
    final state = container.read(notificationControllerProvider);
    expect(state.items.single.isRead, isTrue);
    expect(state.unreadCount, equals(1));
    expect(api.markOneCalls, equals(1));
  });

  test('markAll clears unread without restart', () async {
    final notifier = container.read(notificationControllerProvider.notifier);
    await notifier.load();
    await notifier.markAll();
    final state = container.read(notificationControllerProvider);
    expect(state.unreadCount, equals(0));
    expect(state.items.single.isRead, isTrue);
    expect(api.markAllCalls, equals(1));
    expect(api.listCalls, equals(1));
  });

  test('loadMore uses the cursor', () async {
    api.more = NotificationPage(items: [testInboxNotification(id: '2')]);
    final notifier = container.read(notificationControllerProvider.notifier);
    await notifier.load();
    await notifier.loadMore();
    expect(api.moreCalls, equals(1));
    expect(api.lastAfter, equals('cursor-1'));
    expect(container.read(notificationControllerProvider).items, hasLength(2));
  });
}
