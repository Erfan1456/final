/// Canonical sandbox/provider webhook event types.
enum PaymentWebhookEventType {
  /// Capture/settlement succeeded.
  paymentSucceeded,

  /// Capture/settlement failed.
  paymentFailed,

  /// Full refund settled.
  paymentRefunded,

  /// Partial refund settled.
  paymentPartiallyRefunded;

  /// Stable provider-like wire value.
  String get wireValue {
    switch (this) {
      case PaymentWebhookEventType.paymentSucceeded:
        return 'payment.succeeded';
      case PaymentWebhookEventType.paymentFailed:
        return 'payment.failed';
      case PaymentWebhookEventType.paymentRefunded:
        return 'payment.refunded';
      case PaymentWebhookEventType.paymentPartiallyRefunded:
        return 'payment.partially_refunded';
    }
  }

  /// Parses a provider event type. Unknown values fail.
  static PaymentWebhookEventType fromWire(String value) {
    switch (value) {
      case 'payment.succeeded':
        return PaymentWebhookEventType.paymentSucceeded;
      case 'payment.failed':
        return PaymentWebhookEventType.paymentFailed;
      case 'payment.refunded':
        return PaymentWebhookEventType.paymentRefunded;
      case 'payment.partially_refunded':
        return PaymentWebhookEventType.paymentPartiallyRefunded;
      default:
        throw const FormatException('Unknown PaymentWebhookEventType.');
    }
  }
}
