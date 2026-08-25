/// Cleaner profile persistence and lifecycle failures.
class CleanerProfileDocumentException implements Exception {
  /// Creates a parse failure. [message] must not include field values.
  const CleanerProfileDocumentException(this.message);

  /// Sanitized description of the missing or invalid field.
  final String message;

  @override
  String toString() => 'CleanerProfileDocumentException: $message';
}

/// Thrown when a cleaner profile write cannot be completed.
class CleanerProfileWriteException implements Exception {
  /// Creates a sanitized write failure.
  const CleanerProfileWriteException();

  @override
  String toString() => 'CleanerProfileWriteException';
}

/// Thrown when a unique `user_id` index rejects a second cleaner profile.
class DuplicateCleanerProfileException implements Exception {
  /// Creates a sanitized duplicate-profile failure.
  const DuplicateCleanerProfileException();

  @override
  String toString() => 'DuplicateCleanerProfileException';
}

/// Thrown when submit is attempted without an existing profile.
class CleanerProfileRequiredException implements Exception {
  /// Creates a sanitized missing-profile failure.
  const CleanerProfileRequiredException();

  @override
  String toString() => 'CleanerProfileRequiredException';
}

/// Thrown when a cleaner tries to edit a pending or approved profile.
class CleanerProfileLockedException implements Exception {
  /// Creates a sanitized locked-profile failure.
  const CleanerProfileLockedException();

  @override
  String toString() => 'CleanerProfileLockedException';
}

/// Thrown when a submit/approve/reject is invalid for the current status.
class InvalidOnboardingStateException implements Exception {
  /// Creates a sanitized state-conflict failure.
  const InvalidOnboardingStateException();

  @override
  String toString() => 'InvalidOnboardingStateException';
}

/// Thrown when an admin lookup cannot find the cleaner application.
class CleanerApplicationNotFoundException implements Exception {
  /// Creates a sanitized not-found failure.
  const CleanerApplicationNotFoundException();

  @override
  String toString() => 'CleanerApplicationNotFoundException';
}
