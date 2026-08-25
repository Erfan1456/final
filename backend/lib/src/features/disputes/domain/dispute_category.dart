// ignore_for_file: public_member_api_docs
/// Allowed dispute categories. Arbitrary strings are rejected.
enum DisputeCategory {
  serviceQuality,
  cleanerNoShow,
  customerNoShow,
  paymentIssue,
  bookingIssue,
  conduct,
  other;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case DisputeCategory.serviceQuality:
        return 'service_quality';
      case DisputeCategory.cleanerNoShow:
        return 'cleaner_no_show';
      case DisputeCategory.customerNoShow:
        return 'customer_no_show';
      case DisputeCategory.paymentIssue:
        return 'payment_issue';
      case DisputeCategory.bookingIssue:
        return 'booking_issue';
      case DisputeCategory.conduct:
        return 'conduct';
      case DisputeCategory.other:
        return 'other';
    }
  }

  /// Parses a stored category string. Unknown values fail.
  static DisputeCategory fromWire(String value) {
    switch (value) {
      case 'service_quality':
        return DisputeCategory.serviceQuality;
      case 'cleaner_no_show':
        return DisputeCategory.cleanerNoShow;
      case 'customer_no_show':
        return DisputeCategory.customerNoShow;
      case 'payment_issue':
        return DisputeCategory.paymentIssue;
      case 'booking_issue':
        return DisputeCategory.bookingIssue;
      case 'conduct':
        return DisputeCategory.conduct;
      case 'other':
        return DisputeCategory.other;
      default:
        throw const FormatException('Unknown DisputeCategory.');
    }
  }
}
