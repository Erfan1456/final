// ignore_for_file: public_member_api_docs
/// In-app notification type. Wire values are lowercase snake_case.
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
  reviewReceived;

  /// Stable database/wire representation.
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
    }
  }

  /// Parses a stored type string.
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
        throw const FormatException('Unknown NotificationType.');
    }
  }
}
