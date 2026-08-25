/// TASK 019 payout provider. Only the development sandbox exists.
enum PayoutProviderType {
  /// Development/test sandbox. Not a bank, Stripe, PayPal, or bKash adapter.
  sandbox;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case PayoutProviderType.sandbox:
        return 'sandbox';
    }
  }

  /// Parses a stored provider string.
  static PayoutProviderType fromWire(String value) {
    switch (value) {
      case 'sandbox':
        return PayoutProviderType.sandbox;
      default:
        throw const FormatException('Unknown PayoutProviderType.');
    }
  }
}
