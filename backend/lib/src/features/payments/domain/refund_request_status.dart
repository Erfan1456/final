/// Admin/system refund-request lifecycle. Final payment state comes from webhook.
enum RefundRequestStatus {
  /// Provider refund has been requested and is awaiting webhook settlement.
  pending,

  /// Webhook processing recorded a successful refund application.
  succeeded,

  /// Provider or webhook processing failed. Payment state is unchanged.
  failed;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case RefundRequestStatus.pending:
        return 'pending';
      case RefundRequestStatus.succeeded:
        return 'succeeded';
      case RefundRequestStatus.failed:
        return 'failed';
    }
  }

  /// Parses a stored refund-request status string.
  static RefundRequestStatus fromWire(String value) {
    switch (value) {
      case 'pending':
        return RefundRequestStatus.pending;
      case 'succeeded':
        return RefundRequestStatus.succeeded;
      case 'failed':
        return RefundRequestStatus.failed;
      default:
        throw const FormatException('Unknown RefundRequestStatus.');
    }
  }
}
