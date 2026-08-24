/// Thrown when creating a user would violate unique `email_normalized`.
class DuplicateUserEmailException implements Exception {
  /// Creates a sanitized duplicate-email failure.
  const DuplicateUserEmailException();

  @override
  String toString() => 'DuplicateUserEmailException';
}

/// Thrown when a user document cannot be written for a non-duplicate reason.
class UserAccountWriteException implements Exception {
  /// Creates a sanitized write failure. It must not include secrets.
  const UserAccountWriteException();

  @override
  String toString() => 'UserAccountWriteException';
}

/// Thrown when a MongoDB user document cannot be parsed.
class UserAccountDocumentException implements Exception {
  /// Creates a parse failure. [message] must not include field values.
  const UserAccountDocumentException(this.message);

  /// Sanitized description of the missing or invalid field.
  final String message;

  @override
  String toString() => 'UserAccountDocumentException: $message';
}
