// ignore_for_file: public_member_api_docs
/// Thrown when a notification document cannot be parsed.
class NotificationDocumentException implements Exception {
  const NotificationDocumentException(this.message);

  final String message;

  @override
  String toString() => 'NotificationDocumentException';
}

/// Thrown when a notification write cannot be completed.
class NotificationWriteException implements Exception {
  const NotificationWriteException();

  @override
  String toString() => 'NotificationWriteException';
}

/// Thrown when a unique user+dedupe index rejects an insert.
class NotificationDuplicateKeyException implements Exception {
  const NotificationDuplicateKeyException();

  @override
  String toString() => 'NotificationDuplicateKeyException';
}

/// Thrown when a notification is missing or not owned.
class NotificationNotFoundException implements Exception {
  const NotificationNotFoundException();

  @override
  String toString() => 'NotificationNotFoundException';
}
