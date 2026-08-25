/// Lifecycle of a stored provider webhook event.
enum PaymentWebhookProcessingStatus {
  /// Unique event accepted and not yet applied.
  received,

  /// Event applied a valid payment transition.
  processed,

  /// Event acknowledged without changing payment state.
  ignored,

  /// Event failed during processing after being recorded.
  failed;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case PaymentWebhookProcessingStatus.received:
        return 'received';
      case PaymentWebhookProcessingStatus.processed:
        return 'processed';
      case PaymentWebhookProcessingStatus.ignored:
        return 'ignored';
      case PaymentWebhookProcessingStatus.failed:
        return 'failed';
    }
  }

  /// Parses a stored processing-status string.
  static PaymentWebhookProcessingStatus fromWire(String value) {
    switch (value) {
      case 'received':
        return PaymentWebhookProcessingStatus.received;
      case 'processed':
        return PaymentWebhookProcessingStatus.processed;
      case 'ignored':
        return PaymentWebhookProcessingStatus.ignored;
      case 'failed':
        return PaymentWebhookProcessingStatus.failed;
      default:
        throw const FormatException('Unknown PaymentWebhookProcessingStatus.');
    }
  }
}
