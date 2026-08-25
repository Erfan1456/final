enum NotificationType {
  bookingRequested,
  bookingConfirmed,
  bookingDeclined,
  bookingCancelled,
  jobStarted,
  jobCompleted,
  paymentPaid,
  paymentFailed,
  paymentRefunded,
  messageReceived,
  reviewReceived,
  unknown;

  static NotificationType fromWire(String value) {
    switch (value) {
      case 'booking_requested':
        return NotificationType.bookingRequested;
      case 'booking_confirmed':
        return NotificationType.bookingConfirmed;
      case 'booking_declined':
        return NotificationType.bookingDeclined;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      case 'job_started':
        return NotificationType.jobStarted;
      case 'job_completed':
        return NotificationType.jobCompleted;
      case 'payment_paid':
        return NotificationType.paymentPaid;
      case 'payment_failed':
        return NotificationType.paymentFailed;
      case 'payment_refunded':
        return NotificationType.paymentRefunded;
      case 'message_received':
        return NotificationType.messageReceived;
      case 'review_received':
        return NotificationType.reviewReceived;
      default:
        return NotificationType.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case NotificationType.bookingRequested:
        return 'booking_requested';
      case NotificationType.bookingConfirmed:
        return 'booking_confirmed';
      case NotificationType.bookingDeclined:
        return 'booking_declined';
      case NotificationType.bookingCancelled:
        return 'booking_cancelled';
      case NotificationType.jobStarted:
        return 'job_started';
      case NotificationType.jobCompleted:
        return 'job_completed';
      case NotificationType.paymentPaid:
        return 'payment_paid';
      case NotificationType.paymentFailed:
        return 'payment_failed';
      case NotificationType.paymentRefunded:
        return 'payment_refunded';
      case NotificationType.messageReceived:
        return 'message_received';
      case NotificationType.reviewReceived:
        return 'review_received';
      case NotificationType.unknown:
        return 'unknown';
    }
  }
}

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.resourceType,
    this.resourceId,
    this.readAt,
  });

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: _requireString(json, 'id'),
      type: NotificationType.fromWire(_requireString(json, 'type')),
      title: _requireString(json, 'title'),
      body: _requireString(json, 'body'),
      resourceType: json['resource_type'] is String
          ? json['resource_type'] as String
          : null,
      resourceId: json['resource_id'] is String
          ? json['resource_id'] as String
          : null,
      readAt: _optionalDate(json, 'read_at'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
    );
  }

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? resourceType;
  final String? resourceId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  InboxNotification copyWith({DateTime? readAt}) {
    return InboxNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      resourceType: resourceType,
      resourceId: resourceId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationPage {
  const NotificationPage({required this.items, this.nextCursor});

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final next = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Notification page JSON is invalid.');
    }
    return NotificationPage(
      items: [
        for (final item in items)
          if (item is Map)
            InboxNotification.fromJson(Map<String, dynamic>.from(item)),
      ],
      nextCursor: next is String ? next : null,
    );
  }

  final List<InboxNotification> items;
  final String? nextCursor;
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Notification JSON field $key is invalid.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Notification JSON field $key is invalid.');
  }
  return DateTime.parse(value).toUtc();
}
