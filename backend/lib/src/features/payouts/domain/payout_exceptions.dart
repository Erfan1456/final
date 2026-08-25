/// Thrown when a payout document cannot be parsed.
class PayoutDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const PayoutDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'PayoutDocumentException';
}

/// Thrown when a payout write cannot be completed.
class PayoutWriteException implements Exception {
  /// Creates a sanitized write failure.
  const PayoutWriteException();

  @override
  String toString() => 'PayoutWriteException';
}

/// Thrown when a unique index rejects a payout insert.
class PayoutDuplicateKeyException implements Exception {
  /// Creates a sanitized duplicate-key failure.
  const PayoutDuplicateKeyException();

  @override
  String toString() => 'PayoutDuplicateKeyException';
}

/// Thrown when an owned or admin payout cannot be found.
class PayoutNotFoundException implements Exception {
  /// Creates a sanitized missing-payout failure.
  const PayoutNotFoundException();

  @override
  String toString() => 'PayoutNotFoundException';
}

/// Thrown when another active payout already exists for the cleaner.
class PayoutAlreadyActiveException implements Exception {
  /// Creates a sanitized active-conflict failure.
  const PayoutAlreadyActiveException();

  @override
  String toString() => 'PayoutAlreadyActiveException';
}

/// Thrown when available balance is insufficient or not positive.
class InsufficientPayoutBalanceException implements Exception {
  /// Creates a sanitized insufficient-balance failure.
  const InsufficientPayoutBalanceException();

  @override
  String toString() => 'InsufficientPayoutBalanceException';
}

/// Thrown when no payout provider is available for the current environment.
class PayoutProviderUnavailableException implements Exception {
  /// Creates a sanitized provider-unavailable failure.
  const PayoutProviderUnavailableException();

  @override
  String toString() => 'PayoutProviderUnavailableException';
}

/// Thrown when a payout webhook HMAC signature is missing or invalid.
class InvalidPayoutWebhookSignatureException implements Exception {
  /// Creates a sanitized signature failure.
  const InvalidPayoutWebhookSignatureException();

  @override
  String toString() => 'InvalidPayoutWebhookSignatureException';
}

/// Thrown when the same provider event id arrives with a different payload.
class PayoutWebhookEventConflictException implements Exception {
  /// Creates a sanitized event-conflict failure.
  const PayoutWebhookEventConflictException();

  @override
  String toString() => 'PayoutWebhookEventConflictException';
}

/// Thrown when a webhook amount or currency does not match the payout.
class PayoutIntegrityMismatchException implements Exception {
  /// Creates a sanitized integrity failure.
  const PayoutIntegrityMismatchException();

  @override
  String toString() => 'PayoutIntegrityMismatchException';
}

/// Thrown when a payout action is not allowed in the current state.
class InvalidPayoutStateException implements Exception {
  /// Creates a sanitized invalid-state failure.
  const InvalidPayoutStateException();

  @override
  String toString() => 'InvalidPayoutStateException';
}

/// Thrown when a payout amount is not a positive integer.
class InvalidPayoutAmountException implements Exception {
  /// Creates a sanitized amount failure.
  const InvalidPayoutAmountException();

  @override
  String toString() => 'InvalidPayoutAmountException';
}

/// Thrown when a payout currency is missing or invalid.
class InvalidPayoutCurrencyException implements Exception {
  /// Creates a sanitized currency failure.
  const InvalidPayoutCurrencyException();

  @override
  String toString() => 'InvalidPayoutCurrencyException';
}

/// Thrown when a payout rejection reason is missing or invalid.
class InvalidPayoutRejectionReasonException implements Exception {
  /// Creates a sanitized rejection-reason failure.
  const InvalidPayoutRejectionReasonException({
    this.message = 'Rejection reason is invalid.',
  });

  /// Safe client-facing message.
  final String message;

  @override
  String toString() => 'InvalidPayoutRejectionReasonException';
}

/// Thrown when a payout webhook body cannot be parsed.
class MalformedPayoutWebhookException implements Exception {
  /// Creates a sanitized malformed-webhook failure.
  const MalformedPayoutWebhookException();

  @override
  String toString() => 'MalformedPayoutWebhookException';
}
