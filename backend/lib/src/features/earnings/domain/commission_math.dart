/// Integer-only platform commission math. Never uses [double].
abstract final class CommissionMath {
  /// Round-half-up platform fee:
  /// `(gross * commission_bps + 5000) ~/ 10000`.
  static int platformFeeMinor({
    required int grossMinor,
    required int commissionBps,
  }) {
    return (grossMinor * commissionBps + 5000) ~/ 10000;
  }

  /// Cleaner net after the snapshotted platform fee.
  static int cleanerNetMinor({
    required int grossMinor,
    required int commissionBps,
  }) {
    return grossMinor -
        platformFeeMinor(
          grossMinor: grossMinor,
          commissionBps: commissionBps,
        );
  }
}
