/// Thrown when authentication JSON/input cannot be accepted.
class InvalidAuthInputException implements Exception {
  /// Creates a sanitized input failure with a stable [code].
  const InvalidAuthInputException({
    required this.code,
    required this.message,
  });

  /// Machine-readable error code for HTTP mapping.
  final String code;

  /// Safe client-facing message. Must not include secrets or parser details.
  final String message;

  @override
  String toString() => 'InvalidAuthInputException';
}

/// Thrown when login email/password cannot be authenticated.
///
/// Used for both unknown emails and wrong passwords.
class InvalidCredentialsException implements Exception {
  /// Creates a sanitized credential failure.
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

/// Thrown when a verified password belongs to a non-active account.
class AccountUnavailableException implements Exception {
  /// Creates a sanitized account-status failure.
  const AccountUnavailableException();

  @override
  String toString() => 'AccountUnavailableException';
}

/// Thrown when refresh cannot issue new tokens.
///
/// Covers unknown, expired, revoked, replayed, and unavailable-user cases
/// without distinguishing them to the client.
class InvalidRefreshCredentialsException implements Exception {
  /// Creates a sanitized refresh failure.
  const InvalidRefreshCredentialsException();

  @override
  String toString() => 'InvalidRefreshCredentialsException';
}

/// Thrown when authentication cannot run because configuration is missing.
class AuthenticationConfigurationException implements Exception {
  /// Creates a sanitized configuration failure. Must not include the reason.
  const AuthenticationConfigurationException();

  @override
  String toString() => 'AuthenticationConfigurationException';
}

/// Thrown when the request Content-Type is not JSON.
class UnsupportedMediaTypeException implements Exception {
  /// Creates a sanitized media-type failure.
  const UnsupportedMediaTypeException();

  @override
  String toString() => 'UnsupportedMediaTypeException';
}

/// Thrown when the body is not a JSON object.
class InvalidJsonBodyException implements Exception {
  /// Creates a sanitized JSON parse failure. Must not include parser text.
  const InvalidJsonBodyException();

  @override
  String toString() => 'InvalidJsonBodyException';
}
