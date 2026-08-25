/// Thrown when profile or address input cannot be accepted.
class ProfileValidationException implements Exception {
  /// Creates a sanitized validation failure.
  const ProfileValidationException({
    required this.message,
    this.code = 'invalid_input',
  });

  /// Machine-readable error code for HTTP mapping.
  final String code;

  /// Safe client-facing message. Must not include secrets or parser details.
  final String message;

  @override
  String toString() => 'ProfileValidationException';
}
