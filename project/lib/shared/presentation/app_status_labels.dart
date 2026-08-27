/// Central user-facing status labels for marketplace domains.
///
/// Unknown wire values never crash; they return a safe fallback.
abstract final class AppStatusLabels {
  static const String unknown = 'Unknown';
  static const String unsupported = 'Unsupported Status';

  static String booking(String? wire) {
    switch (wire) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      case null:
      case '':
        return unknown;
      default:
        return unsupported;
    }
  }

  static String payment(String? wire) {
    switch (wire) {
      case 'pending':
        return 'Pending';
      case 'authorized':
        return 'Authorized';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'partially_refunded':
        return 'Partially Refunded';
      case 'refunded':
        return 'Refunded';
      case null:
      case '':
        return unknown;
      default:
        return unsupported;
    }
  }

  static String payout(String? wire) {
    switch (wire) {
      case 'requested':
        return 'Requested';
      case 'processing':
        return 'Processing';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case null:
      case '':
        return unknown;
      default:
        return unsupported;
    }
  }

  static String dispute(String? wire) {
    switch (wire) {
      case 'open':
        return 'Open';
      case 'under_review':
        return 'Under Review';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case null:
      case '':
        return unknown;
      default:
        return unsupported;
    }
  }

  static String review(String? wire) {
    switch (wire) {
      case 'published':
        return 'Published';
      case 'hidden':
        return 'Hidden';
      case null:
      case '':
        return unknown;
      default:
        return unsupported;
    }
  }

  static String onboarding(String? wire) {
    switch (wire) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case null:
      case '':
        return unknown;
      default:
        return unsupported;
    }
  }
}
