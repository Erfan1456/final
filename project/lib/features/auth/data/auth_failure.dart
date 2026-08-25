/// Stable client-side authentication failure.
///
/// Does not expose Dio internals, tokens, or parser details.
class AuthFailure implements Exception {
  /// Creates a sanitized failure.
  const AuthFailure({required this.code, required this.message});

  /// Machine-readable code from the backend or a local client code.
  final String code;

  /// Safe user-readable message.
  final String message;

  /// Whether local tokens should be discarded.
  bool get isSessionInvalid =>
      code == 'invalid_access_token' || code == 'invalid_refresh_token';

  @override
  String toString() => 'AuthFailure($code)';
}
