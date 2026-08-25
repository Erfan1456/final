// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/app_notification.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent notification feed and idempotent creation.
class NotificationService implements NotificationSink {
  /// Creates a notification service.
  NotificationService({
    required NotificationRepository notifications,
    DateTime Function()? clock,
  }) : _notifications = notifications,
       _clock = clock ?? DateTime.now;

  final NotificationRepository _notifications;
  final DateTime Function() _clock;

  @override
  Future<void> createIdempotentNotification({
    required ObjectId userId,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? resourceType,
    ObjectId? resourceId,
  }) async {
    final existing = await _notifications.findByUserDedupe(
      userId: userId,
      dedupeKey: dedupeKey,
    );
    if (existing != null) {
      return;
    }
    try {
      await _notifications.create(
        AppNotification(
          id: ObjectId(),
          userId: userId,
          type: type,
          title: title,
          body: body,
          resourceType: resourceType,
          resourceId: resourceId,
          dedupeKey: dedupeKey,
          createdAt: _clock().toUtc(),
        ),
      );
    } on NotificationDuplicateKeyException {
      return;
    }
  }

  @override
  Future<void> notifyBestEffort({
    required ObjectId userId,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? resourceType,
    ObjectId? resourceId,
  }) async {
    try {
      await createIdempotentNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        dedupeKey: dedupeKey,
        resourceType: resourceType,
        resourceId: resourceId,
      );
    } catch (_) {}
  }

  /// Lists notifications for the authenticated user.
  Future<Map<String, Object?>> listForUser({
    required UserAccount user,
    Object? unread,
    Object? limitRaw,
    Object? after,
  }) async {
    final query = NotificationValidation.parseListQuery(
      unread: unread,
      limitRaw: limitRaw,
      after: after,
    );
    final page = await _notifications.listForUser(
      userId: user.id,
      limit: query.limit,
      unread: query.unread,
      after: query.after,
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toPublicJson()],
      'next_cursor': page.nextCursor,
    };
  }

  /// Unread count for the authenticated user.
  Future<Map<String, Object?>> unreadCount({required UserAccount user}) async {
    final count = await _notifications.unreadCount(user.id);
    return <String, Object?>{'unread_count': count};
  }

  /// Marks one owned notification read.
  Future<Map<String, Object?>> markRead({
    required UserAccount user,
    required ObjectId notificationId,
  }) async {
    final updated = await _notifications.markReadOwned(
      id: notificationId,
      userId: user.id,
      now: _clock().toUtc(),
    );
    if (updated == null) {
      throw const NotificationNotFoundException();
    }
    return updated.toPublicJson();
  }

  /// Marks all owned notifications read.
  Future<Map<String, Object?>> markAllRead({required UserAccount user}) async {
    final updated = await _notifications.markAllRead(
      userId: user.id,
      now: _clock().toUtc(),
    );
    final remaining = await _notifications.unreadCount(user.id);
    return <String, Object?>{
      'updated_count': updated,
      'unread_count': remaining,
    };
  }

  /// Truncates a safe message preview to 120 Unicode code points.
  static String preview(String body, {int maxCodePoints = 120}) {
    final trimmed = body.trim();
    if (trimmed.runes.length <= maxCodePoints) {
      return trimmed;
    }
    return String.fromCharCodes(trimmed.runes.take(maxCodePoints));
  }
}
