// ignore_for_file: public_member_api_docs
class AuditLogDocumentException implements Exception {
  const AuditLogDocumentException(this.message);

  final String message;

  @override
  String toString() => 'AuditLogDocumentException';
}

class AuditLogWriteException implements Exception {
  const AuditLogWriteException();

  @override
  String toString() => 'AuditLogWriteException';
}

class AuditLogNotFoundException implements Exception {
  const AuditLogNotFoundException();

  @override
  String toString() => 'AuditLogNotFoundException';
}

class InvalidAuditQueryException implements Exception {
  const InvalidAuditQueryException();

  @override
  String toString() => 'InvalidAuditQueryException';
}
