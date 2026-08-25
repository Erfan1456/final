/// Thrown when a customer profile write cannot be completed.
class CustomerProfileWriteException implements Exception {
  /// Creates a sanitized write failure.
  const CustomerProfileWriteException();

  @override
  String toString() => 'CustomerProfileWriteException';
}

/// Thrown when a unique `user_id` index rejects a second customer profile.
class DuplicateCustomerProfileException implements Exception {
  /// Creates a sanitized duplicate-profile failure.
  const DuplicateCustomerProfileException();

  @override
  String toString() => 'DuplicateCustomerProfileException';
}

/// Thrown when a default address cannot be set because no profile exists.
class CustomerProfileRequiredException implements Exception {
  /// Creates a sanitized missing-profile failure.
  const CustomerProfileRequiredException();

  @override
  String toString() => 'CustomerProfileRequiredException';
}
