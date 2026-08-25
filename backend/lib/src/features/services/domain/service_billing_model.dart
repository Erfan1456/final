/// Platform billing model for a catalog service.
enum ServiceBillingModel {
  /// Hourly billing. The only model implemented in TASK 014.
  hourly;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case ServiceBillingModel.hourly:
        return 'hourly';
    }
  }

  /// Parses a stored billing-model string. Unknown values fail.
  static ServiceBillingModel fromWire(String value) {
    switch (value) {
      case 'hourly':
        return ServiceBillingModel.hourly;
      default:
        throw const FormatException('Unknown ServiceBillingModel.');
    }
  }
}
