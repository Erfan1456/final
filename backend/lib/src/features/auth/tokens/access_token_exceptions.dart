/// Thrown when ACCESS_TOKEN_SECRET is missing or shorter than 32 UTF-8 bytes.
///
/// Must not include the secret value.
class AccessTokenConfigurationException implements Exception {
  /// Creates a sanitized configuration failure.
  const AccessTokenConfigurationException();

  @override
  String toString() => 'AccessTokenConfigurationException';
}

/// Thrown when an access token cannot be verified or parsed.
///
/// Must not include the token, secret, or claim values.
class InvalidAccessTokenException implements Exception {
  /// Creates a sanitized invalid-token failure.
  const InvalidAccessTokenException();

  @override
  String toString() => 'InvalidAccessTokenException';
}
