/// Sandbox payout webhook event types.
enum PayoutWebhookEventType {
  /// Provider reported a successful payout.
  payoutPaid,

  /// Provider reported a failed payout.
  payoutFailed;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case PayoutWebhookEventType.payoutPaid:
        return 'payout.paid';
      case PayoutWebhookEventType.payoutFailed:
        return 'payout.failed';
    }
  }

  /// Parses a stored event-type string.
  static PayoutWebhookEventType fromWire(String value) {
    switch (value) {
      case 'payout.paid':
        return PayoutWebhookEventType.payoutPaid;
      case 'payout.failed':
        return PayoutWebhookEventType.payoutFailed;
      default:
        throw const FormatException('Unknown PayoutWebhookEventType.');
    }
  }
}
