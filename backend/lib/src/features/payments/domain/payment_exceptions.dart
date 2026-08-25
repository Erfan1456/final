/// Thrown when a payment document cannot be parsed.
class PaymentDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const PaymentDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'PaymentDocumentException';
}

/// Thrown when a payment write cannot be completed.
class PaymentWriteException implements Exception {
  /// Creates a sanitized write failure.
  const PaymentWriteException();

  @override
  String toString() => 'PaymentWriteException';
}

/// Thrown when a unique index rejects a payment insert.
class PaymentDuplicateKeyException implements Exception {
  /// Creates a sanitized duplicate-key failure.
  const PaymentDuplicateKeyException();

  @override
  String toString() => 'PaymentDuplicateKeyException';
}

/// Thrown when an owned or admin payment cannot be found.
class PaymentNotFoundException implements Exception {
  /// Creates a sanitized missing-payment failure.
  const PaymentNotFoundException();

  @override
  String toString() => 'PaymentNotFoundException';
}

/// Thrown when a booking is not in a payable lifecycle state.
class BookingNotPayableException implements Exception {
  /// Creates a sanitized not-payable failure.
  const BookingNotPayableException();

  @override
  String toString() => 'BookingNotPayableException';
}

/// Thrown when another active charge attempt already exists.
class PaymentAlreadyActiveException implements Exception {
  /// Creates a sanitized active-conflict failure.
  const PaymentAlreadyActiveException();

  @override
  String toString() => 'PaymentAlreadyActiveException';
}

/// Thrown when a successful settlement already exists for the booking.
class PaymentAlreadyPaidException implements Exception {
  /// Creates a sanitized already-paid failure.
  const PaymentAlreadyPaidException();

  @override
  String toString() => 'PaymentAlreadyPaidException';
}

/// Thrown when no payment provider is available for the current environment.
class PaymentProviderUnavailableException implements Exception {
  /// Creates a sanitized provider-unavailable failure.
  const PaymentProviderUnavailableException();

  @override
  String toString() => 'PaymentProviderUnavailableException';
}

/// Thrown when a webhook HMAC signature is missing or invalid.
class InvalidWebhookSignatureException implements Exception {
  /// Creates a sanitized signature failure.
  const InvalidWebhookSignatureException();

  @override
  String toString() => 'InvalidWebhookSignatureException';
}

/// Thrown when the same provider event id arrives with a different payload.
class WebhookEventConflictException implements Exception {
  /// Creates a sanitized event-conflict failure.
  const WebhookEventConflictException();

  @override
  String toString() => 'WebhookEventConflictException';
}

/// Thrown when a webhook amount or currency does not match the payment.
class PaymentIntegrityMismatchException implements Exception {
  /// Creates a sanitized integrity failure.
  const PaymentIntegrityMismatchException();

  @override
  String toString() => 'PaymentIntegrityMismatchException';
}

/// Thrown when a payment action is not allowed in the current state.
class InvalidPaymentStateException implements Exception {
  /// Creates a sanitized invalid-state failure.
  const InvalidPaymentStateException();

  @override
  String toString() => 'InvalidPaymentStateException';
}

/// Thrown when a required refund cannot be completed.
class PaymentRefundFailedException implements Exception {
  /// Creates a sanitized refund-failure.
  const PaymentRefundFailedException();

  @override
  String toString() => 'PaymentRefundFailedException';
}

/// Thrown when a refund amount is out of range.
class InvalidRefundAmountException implements Exception {
  /// Creates a sanitized refund-amount failure.
  const InvalidRefundAmountException();

  @override
  String toString() => 'InvalidRefundAmountException';
}

/// Thrown when a refund reason is missing or invalid.
class InvalidRefundReasonException implements Exception {
  /// Creates a sanitized refund-reason failure.
  const InvalidRefundReasonException({
    this.message = 'Refund reason is invalid.',
  });

  /// Safe client-facing message.
  final String message;

  @override
  String toString() => 'InvalidRefundReasonException';
}

/// Thrown when a webhook body cannot be parsed or the event type is unknown.
class MalformedWebhookException implements Exception {
  /// Creates a sanitized malformed-webhook failure.
  const MalformedWebhookException();

  @override
  String toString() => 'MalformedWebhookException';
}
