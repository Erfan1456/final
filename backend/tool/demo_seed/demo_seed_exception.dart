/// Tool-owned seed error whose [message] is guaranteed free of secrets.
///
/// Only throw this for intentionally user-facing, non-sensitive failures
/// (wrong database name, missing flags, validation messages without URIs).
class DemoSeedException implements Exception {
  /// Creates a safe seed error.
  const DemoSeedException(this.message);

  /// Human-readable message. Must never include URI, credentials, or env dumps.
  final String message;

  @override
  String toString() => 'DemoSeedException: $message';
}
