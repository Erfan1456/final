/// Thrown when an availability slot document cannot be parsed.
class AvailabilityDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const AvailabilityDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'AvailabilityDocumentException';
}

/// Thrown when a slot write cannot be completed.
class AvailabilityWriteException implements Exception {
  /// Creates a sanitized write failure.
  const AvailabilityWriteException();

  @override
  String toString() => 'AvailabilityWriteException';
}

/// Thrown when an owned future slot cannot be found.
class AvailabilityNotFoundException implements Exception {
  /// Creates a sanitized missing-slot failure.
  const AvailabilityNotFoundException();

  @override
  String toString() => 'AvailabilityNotFoundException';
}

/// Thrown when a proposed slot overlaps an existing slot.
class AvailabilityOverlapException implements Exception {
  /// Creates a sanitized overlap failure.
  const AvailabilityOverlapException();

  @override
  String toString() => 'AvailabilityOverlapException';
}

/// Thrown when the cleaner has reached the future-slot product limit.
class AvailabilityLimitReachedException implements Exception {
  /// Creates a sanitized limit failure.
  const AvailabilityLimitReachedException();

  @override
  String toString() => 'AvailabilityLimitReachedException';
}

/// Thrown when timestamps, duration, or range rules fail.
class InvalidAvailabilityWindowException implements Exception {
  /// Creates a sanitized window-validation failure.
  const InvalidAvailabilityWindowException({
    this.message = 'The availability window is invalid.',
  });

  /// Safe client-facing message.
  final String message;

  @override
  String toString() => 'InvalidAvailabilityWindowException';
}
