// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Narrow sink used by booking/payment/chat/review services.
abstract class NotificationSink {
  /// Creates an idempotent notification or no-ops if the dedupe key exists.
  Future<void> createIdempotentNotification({
    required ObjectId userId,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? resourceType,
    ObjectId? resourceId,
  });

  /// Best-effort wrapper: swallows unexpected write failures.
  Future<void> notifyBestEffort({
    required ObjectId userId,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? resourceType,
    ObjectId? resourceId,
  });
}

/// No-op sink used when notifications are not wired.
class NoOpNotificationSink implements NotificationSink {
  /// Creates a sink that ignores all notifications.
  const NoOpNotificationSink();

  @override
  Future<void> createIdempotentNotification({
    required ObjectId userId,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? resourceType,
    ObjectId? resourceId,
  }) async {}

  @override
  Future<void> notifyBestEffort({
    required ObjectId userId,
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? resourceType,
    ObjectId? resourceId,
  }) async {}
}
