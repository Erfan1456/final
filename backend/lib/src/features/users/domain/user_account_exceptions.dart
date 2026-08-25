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

/// Thrown when a user document cannot be parsed.
class UserAccountDocumentException implements Exception {
  /// Creates a parse failure. [message] must not include field values.
  const UserAccountDocumentException(this.message);

  /// Sanitized description of the missing or invalid field.
  final String message;

  @override
  String toString() => 'UserAccountDocumentException: $message';
}

/// Thrown when an admin user path id is unknown.
class UserNotFoundException implements Exception {
  /// Creates a sanitized missing-user failure.
  const UserNotFoundException();

  @override
  String toString() => 'UserNotFoundException';
}

/// Thrown when an administrator account is targeted by operational moderation.
class ProtectedAdminAccountException implements Exception {
  /// Creates a sanitized protected-admin failure.
  const ProtectedAdminAccountException();

  @override
  String toString() => 'ProtectedAdminAccountException';
}

/// Thrown when an account status transition is not allowed.
class InvalidAccountStateException implements Exception {
  /// Creates a sanitized invalid-state failure.
  const InvalidAccountStateException();

  @override
  String toString() => 'InvalidAccountStateException';
}

/// Thrown when a moderation reason is invalid.
class InvalidModerationReasonException implements Exception {
  /// Creates a sanitized reason failure. [message] must not include secrets.
  const InvalidModerationReasonException({required this.message});

  /// Sanitized validation message.
  final String message;

  @override
  String toString() => 'InvalidModerationReasonException';
}

/// Thrown when an admin user list query is invalid.
class InvalidAdminUserQueryException implements Exception {
  /// Creates a sanitized query failure.
  const InvalidAdminUserQueryException();

  @override
  String toString() => 'InvalidAdminUserQueryException';
}
