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
  reviewReceived,
  disputeOpened,
  disputeUnderReview,
  disputeResolved,
  disputeClosed,
  payoutRequested,
  payoutProcessing,
  payoutPaid,
  payoutFailed,
  payoutRejected,
  payoutCancelled;

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
      case NotificationType.disputeOpened:
        return 'dispute_opened';
      case NotificationType.disputeUnderReview:
        return 'dispute_under_review';
      case NotificationType.disputeResolved:
        return 'dispute_resolved';
      case NotificationType.disputeClosed:
        return 'dispute_closed';
      case NotificationType.payoutRequested:
        return 'payout_requested';
      case NotificationType.payoutProcessing:
        return 'payout_processing';
      case NotificationType.payoutPaid:
        return 'payout_paid';
      case NotificationType.payoutFailed:
        return 'payout_failed';
      case NotificationType.payoutRejected:
        return 'payout_rejected';
      case NotificationType.payoutCancelled:
        return 'payout_cancelled';
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
      case 'dispute_opened':
        return NotificationType.disputeOpened;
      case 'dispute_under_review':
        return NotificationType.disputeUnderReview;
      case 'dispute_resolved':
        return NotificationType.disputeResolved;
      case 'dispute_closed':
        return NotificationType.disputeClosed;
      case 'payout_requested':
        return NotificationType.payoutRequested;
      case 'payout_processing':
        return NotificationType.payoutProcessing;
      case 'payout_paid':
        return NotificationType.payoutPaid;
      case 'payout_failed':
        return NotificationType.payoutFailed;
      case 'payout_rejected':
        return NotificationType.payoutRejected;
      case 'payout_cancelled':
        return NotificationType.payoutCancelled;
      default:
        throw const FormatException('Unknown NotificationType.');
    }
  }
}
