/// Thrown when a cleaner service offering document cannot be parsed.
class CleanerServiceDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const CleanerServiceDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'CleanerServiceDocumentException';
}

/// Thrown when an offering write cannot be completed.
class CleanerServiceWriteException implements Exception {
  /// Creates a sanitized write failure.
  const CleanerServiceWriteException();

  @override
  String toString() => 'CleanerServiceWriteException';
}

/// Thrown when an offering cannot be found for the authenticated cleaner.
class CleanerServiceNotFoundException implements Exception {
  /// Creates a sanitized missing-offering failure.
  const CleanerServiceNotFoundException();

  @override
  String toString() => 'CleanerServiceNotFoundException';
}

/// Thrown when the cleaner is not approved to manage services or availability.
class CleanerNotApprovedException implements Exception {
  /// Creates a sanitized approval-policy failure.
  const CleanerNotApprovedException();

  @override
  String toString() => 'CleanerNotApprovedException';
}

/// Thrown when a customer cannot see a cleaner in discovery.
class CleanerNotFoundException implements Exception {
  /// Creates a sanitized missing-discovery-target failure.
  const CleanerNotFoundException();

  @override
  String toString() => 'CleanerNotFoundException';
}
