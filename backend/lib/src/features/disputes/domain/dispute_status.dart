// ignore_for_file: public_member_api_docs
/// Booking dispute lifecycle status. Wire values are lowercase snake_case.
enum DisputeStatus {
  /// Newly opened by a booking participant.
  open,

  /// An administrator has started operational review.
  underReview,

  /// An administrator recorded an operational resolution.
  resolved,

  /// Terminal. A closed dispute cannot be reopened in TASK 018.
  closed;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case DisputeStatus.open:
        return 'open';
      case DisputeStatus.underReview:
        return 'under_review';
      case DisputeStatus.resolved:
        return 'resolved';
      case DisputeStatus.closed:
        return 'closed';
    }
  }

  /// Whether this status still occupies the one-dispute-per-booking slot.
  bool get occupiesBookingSlot => true;

  /// Parses a stored status string. Unknown values fail.
  static DisputeStatus fromWire(String value) {
    switch (value) {
      case 'open':
        return DisputeStatus.open;
      case 'under_review':
        return DisputeStatus.underReview;
      case 'resolved':
        return DisputeStatus.resolved;
      case 'closed':
        return DisputeStatus.closed;
      default:
        throw const FormatException('Unknown DisputeStatus.');
    }
  }
}
