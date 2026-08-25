/// Thrown when an earnings ledger document cannot be parsed.
class EarningsDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const EarningsDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'EarningsDocumentException';
}

/// Thrown when an earnings ledger write cannot be completed.
class EarningsWriteException implements Exception {
  /// Creates a sanitized write failure.
  const EarningsWriteException();

  @override
  String toString() => 'EarningsWriteException';
}

/// Thrown when a unique source-event index rejects a ledger insert.
class EarningsDuplicateKeyException implements Exception {
  /// Creates a sanitized duplicate-key failure.
  const EarningsDuplicateKeyException();

  @override
  String toString() => 'EarningsDuplicateKeyException';
}

/// Thrown when platform commission configuration is not a valid integer bps.
class InvalidPlatformCommissionException implements Exception {
  /// Creates a sanitized commission-configuration failure.
  const InvalidPlatformCommissionException();

  @override
  String toString() => 'InvalidPlatformCommissionException';
}
