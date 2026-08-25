/// Append-only earnings ledger entry type.
///
/// Wire values are lowercase snake_case.
enum EarningsEntryType {
  /// Original cleaner earning for a completed and successfully paid booking.
  serviceEarning,

  /// Incremental refund allocation against an original service earning.
  refundAdjustment;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case EarningsEntryType.serviceEarning:
        return 'service_earning';
      case EarningsEntryType.refundAdjustment:
        return 'refund_adjustment';
    }
  }

  /// Parses a stored entry-type string. Unknown values fail.
  static EarningsEntryType fromWire(String value) {
    switch (value) {
      case 'service_earning':
        return EarningsEntryType.serviceEarning;
      case 'refund_adjustment':
        return EarningsEntryType.refundAdjustment;
      default:
        throw const FormatException('Unknown EarningsEntryType.');
    }
  }
}
