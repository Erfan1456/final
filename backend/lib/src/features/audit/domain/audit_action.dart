// ignore_for_file: public_member_api_docs
/// Explicit administrative audit actions. Do not persist arbitrary strings.
enum AuditAction {
  userSuspended,
  userReactivated,
  userDeactivated,
  cleanerApproved,
  cleanerRejected,
  reviewHidden,
  reviewUnhidden,
  paymentRefundRequested,
  disputeReviewStarted,
  disputeResolved,
  disputeClosed,
  bookingAdminCancelled;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case AuditAction.userSuspended:
        return 'user_suspended';
      case AuditAction.userReactivated:
        return 'user_reactivated';
      case AuditAction.userDeactivated:
        return 'user_deactivated';
      case AuditAction.cleanerApproved:
        return 'cleaner_approved';
      case AuditAction.cleanerRejected:
        return 'cleaner_rejected';
      case AuditAction.reviewHidden:
        return 'review_hidden';
      case AuditAction.reviewUnhidden:
        return 'review_unhidden';
      case AuditAction.paymentRefundRequested:
        return 'payment_refund_requested';
      case AuditAction.disputeReviewStarted:
        return 'dispute_review_started';
      case AuditAction.disputeResolved:
        return 'dispute_resolved';
      case AuditAction.disputeClosed:
        return 'dispute_closed';
      case AuditAction.bookingAdminCancelled:
        return 'booking_admin_cancelled';
    }
  }

  /// Parses a stored action string. Unknown values fail.
  static AuditAction fromWire(String value) {
    switch (value) {
      case 'user_suspended':
        return AuditAction.userSuspended;
      case 'user_reactivated':
        return AuditAction.userReactivated;
      case 'user_deactivated':
        return AuditAction.userDeactivated;
      case 'cleaner_approved':
        return AuditAction.cleanerApproved;
      case 'cleaner_rejected':
        return AuditAction.cleanerRejected;
      case 'review_hidden':
        return AuditAction.reviewHidden;
      case 'review_unhidden':
        return AuditAction.reviewUnhidden;
      case 'payment_refund_requested':
        return AuditAction.paymentRefundRequested;
      case 'dispute_review_started':
        return AuditAction.disputeReviewStarted;
      case 'dispute_resolved':
        return AuditAction.disputeResolved;
      case 'dispute_closed':
        return AuditAction.disputeClosed;
      case 'booking_admin_cancelled':
        return AuditAction.bookingAdminCancelled;
      default:
        throw const FormatException('Unknown AuditAction.');
    }
  }
}

/// Safe target type strings used with [AuditAction].
abstract final class AuditTargetType {
  static const String user = 'user';
  static const String cleanerProfile = 'cleaner_profile';
  static const String review = 'review';
  static const String payment = 'payment';
  static const String dispute = 'dispute';
  static const String booking = 'booking';
}
