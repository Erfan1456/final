/// Thrown when a booking document cannot be parsed.
class BookingDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const BookingDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'BookingDocumentException';
}

/// Thrown when a booking write cannot be completed.
class BookingWriteException implements Exception {
  /// Creates a sanitized write failure.
  const BookingWriteException();

  @override
  String toString() => 'BookingWriteException';
}

/// Thrown when a unique index rejects a booking insert.
class BookingDuplicateKeyException implements Exception {
  /// Creates a sanitized duplicate-key failure.
  const BookingDuplicateKeyException();

  @override
  String toString() => 'BookingDuplicateKeyException';
}

/// Thrown when an owned booking cannot be found.
class BookingNotFoundException implements Exception {
  /// Creates a sanitized missing-booking failure.
  const BookingNotFoundException();

  @override
  String toString() => 'BookingNotFoundException';
}

/// Thrown when a slot cannot be booked for any customer-safe reason.
class AvailabilityUnavailableException implements Exception {
  /// Creates a sanitized unavailability failure.
  const AvailabilityUnavailableException();

  @override
  String toString() => 'AvailabilityUnavailableException';
}

/// Thrown when a lifecycle action is not allowed in the current state.
class InvalidBookingStateException implements Exception {
  /// Creates a sanitized invalid-state failure.
  const InvalidBookingStateException();

  @override
  String toString() => 'InvalidBookingStateException';
}

/// Thrown when booking creation omits Idempotency-Key.
class IdempotencyKeyRequiredException implements Exception {
  /// Creates a sanitized missing-key failure.
  const IdempotencyKeyRequiredException();

  @override
  String toString() => 'IdempotencyKeyRequiredException';
}

/// Thrown when Idempotency-Key syntax is invalid.
class InvalidIdempotencyKeyException implements Exception {
  /// Creates a sanitized key-syntax failure.
  const InvalidIdempotencyKeyException();

  @override
  String toString() => 'InvalidIdempotencyKeyException';
}

/// Thrown when the same key is reused for a different booking intent.
class IdempotencyKeyReusedException implements Exception {
  /// Creates a sanitized key-reuse failure.
  const IdempotencyKeyReusedException();

  @override
  String toString() => 'IdempotencyKeyReusedException';
}

/// Thrown when customer notes cannot be accepted.
class InvalidCustomerNotesException implements Exception {
  /// Creates a sanitized notes-validation failure.
  const InvalidCustomerNotesException({
    this.message = 'Customer notes are invalid.',
  });

  /// Safe client-facing message.
  final String message;

  @override
  String toString() => 'InvalidCustomerNotesException';
}

/// Thrown when a booking cannot be cancelled by an administrator.
class AdminBookingNotCancellableException implements Exception {
  /// Creates a sanitized ineligible-admin-cancel failure.
  const AdminBookingNotCancellableException();

  @override
  String toString() => 'AdminBookingNotCancellableException';
}

/// Thrown when a cleaner tries to edit or delete a reserved availability slot.
class AvailabilityReservedException implements Exception {
  /// Creates a sanitized reserved-slot failure.
  const AvailabilityReservedException();

  @override
  String toString() => 'AvailabilityReservedException';
}
