/// Thrown when an authenticated active user lacks the required role.
class ForbiddenException implements Exception {
  /// Creates a sanitized authorization failure.
  const ForbiddenException();

  @override
  String toString() => 'ForbiddenException';
}
