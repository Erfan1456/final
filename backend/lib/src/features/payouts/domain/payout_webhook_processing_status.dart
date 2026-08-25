/// Lifecycle of a stored payout provider webhook event.
enum PayoutWebhookProcessingStatus {
  /// Unique event accepted and not yet applied.
  received,

  /// Event applied a valid payout transition.
  processed,

  /// Event acknowledged without changing payout state.
  ignored,

  /// Event failed during processing after being recorded.
  failed;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case PayoutWebhookProcessingStatus.received:
        return 'received';
      case PayoutWebhookProcessingStatus.processed:
        return 'processed';
      case PayoutWebhookProcessingStatus.ignored:
        return 'ignored';
      case PayoutWebhookProcessingStatus.failed:
        return 'failed';
    }
  }

  /// Parses a stored processing-status string.
  static PayoutWebhookProcessingStatus fromWire(String value) {
    switch (value) {
      case 'received':
        return PayoutWebhookProcessingStatus.received;
      case 'processed':
        return PayoutWebhookProcessingStatus.processed;
      case 'ignored':
        return PayoutWebhookProcessingStatus.ignored;
      case 'failed':
        return PayoutWebhookProcessingStatus.failed;
      default:
        throw const FormatException('Unknown PayoutWebhookProcessingStatus.');
    }
  }
}
