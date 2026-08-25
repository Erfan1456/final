import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Test sink that records creates and can fail on demand.
class RecordingNotificationSink implements NotificationSink {
  final List<Map<String, Object?>> created = <Map<String, Object?>>[];

  bool throwOnCreate = false;

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
    if (throwOnCreate) {
      throw StateError('notification write failed');
    }
    created.add(<String, Object?>{
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'dedupe_key': dedupeKey,
      'resource_type': resourceType,
      'resource_id': resourceId,
    });
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
}
