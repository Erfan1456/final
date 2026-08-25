/// Address persistence and application failures.
class AddressDocumentException implements Exception {
  /// Creates a parse failure. [message] must not include field values.
  const AddressDocumentException(this.message);

  /// Sanitized description of the missing or invalid field.
  final String message;

  @override
  String toString() => 'AddressDocumentException: $message';
}

/// Thrown when an address write cannot be completed.
class AddressWriteException implements Exception {
  /// Creates a sanitized write failure.
  const AddressWriteException();

  @override
  String toString() => 'AddressWriteException';
}

/// Thrown when the customer already has 20 addresses.
class AddressLimitReachedException implements Exception {
  /// Creates a sanitized product-limit failure.
  const AddressLimitReachedException();

  @override
  String toString() => 'AddressLimitReachedException';
}

/// Thrown when an address is missing or not owned by the caller.
class AddressNotFoundException implements Exception {
  /// Creates a sanitized not-found failure. Does not distinguish ownership.
  const AddressNotFoundException();

  @override
  String toString() => 'AddressNotFoundException';
}
