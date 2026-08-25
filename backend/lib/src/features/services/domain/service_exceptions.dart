/// Thrown when a service catalog document cannot be parsed.
class ServiceDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const ServiceDocumentException(this.message);

  /// Safe diagnostic message. Must not include document contents.
  final String message;

  @override
  String toString() => 'ServiceDocumentException';
}

/// Thrown when a catalog write cannot be completed.
class ServiceWriteException implements Exception {
  /// Creates a sanitized write failure.
  const ServiceWriteException();

  @override
  String toString() => 'ServiceWriteException';
}

/// Thrown when an active platform service cannot be found.
class ServiceNotFoundException implements Exception {
  /// Creates a sanitized missing-service failure.
  const ServiceNotFoundException();

  @override
  String toString() => 'ServiceNotFoundException';
}
