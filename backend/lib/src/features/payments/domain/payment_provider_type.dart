/// Supported payment providers. TASK 016 implements sandbox only.
enum PaymentProviderType {
  /// Development/test sandbox processor. Never a production gateway.
  sandbox;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case PaymentProviderType.sandbox:
        return 'sandbox';
    }
  }

  /// Parses a stored provider string. Unknown values fail.
  static PaymentProviderType fromWire(String value) {
    switch (value) {
      case 'sandbox':
        return PaymentProviderType.sandbox;
      default:
        throw const FormatException('Unknown PaymentProviderType.');
    }
  }
}
