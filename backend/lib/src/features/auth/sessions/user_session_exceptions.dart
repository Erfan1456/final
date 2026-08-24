/// Thrown when a session document cannot be parsed.
class UserSessionDocumentException implements Exception {
  /// Creates a parse failure. [message] must not include field values.
  const UserSessionDocumentException(this.message);

  /// Sanitized description of the missing or invalid field.
  final String message;

  @override
  String toString() => 'UserSessionDocumentException: $message';
}

/// Thrown when a session document cannot be written.
class UserSessionWriteException implements Exception {
  /// Creates a sanitized write failure.
  const UserSessionWriteException();

  @override
  String toString() => 'UserSessionWriteException';
}

/// Thrown when a consumed refresh token is presented again.
class RefreshTokenReuseDetectedException implements Exception {
  /// Creates a sanitized replay failure.
  const RefreshTokenReuseDetectedException();

  @override
  String toString() => 'RefreshTokenReuseDetectedException';
}

/// Thrown when a refresh token is unknown, expired, or revoked.
class InvalidRefreshTokenException implements Exception {
  /// Creates a sanitized invalid-refresh failure.
  const InvalidRefreshTokenException();

  @override
  String toString() => 'InvalidRefreshTokenException';
}
