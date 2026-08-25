// ignore_for_file: public_member_api_docs
/// Thrown when a dispute document cannot be parsed.
class DisputeDocumentException implements Exception {
  const DisputeDocumentException(this.message);

  final String message;

  @override
  String toString() => 'DisputeDocumentException';
}

/// Thrown when a dispute write cannot be completed.
class DisputeWriteException implements Exception {
  const DisputeWriteException();

  @override
  String toString() => 'DisputeWriteException';
}

/// Thrown when the unique booking dispute index rejects an insert.
class DisputeDuplicateKeyException implements Exception {
  const DisputeDuplicateKeyException();

  @override
  String toString() => 'DisputeDuplicateKeyException';
}

/// Thrown when a dispute is missing or not visible to the caller.
class DisputeNotFoundException implements Exception {
  const DisputeNotFoundException();

  @override
  String toString() => 'DisputeNotFoundException';
}

/// Thrown when a second dispute would be created for the same booking.
class DisputeAlreadyExistsException implements Exception {
  const DisputeAlreadyExistsException();

  @override
  String toString() => 'DisputeAlreadyExistsException';
}

/// Thrown when the booking is not eligible for a dispute.
class DisputeNotAllowedException implements Exception {
  const DisputeNotAllowedException();

  @override
  String toString() => 'DisputeNotAllowedException';
}

/// Thrown when a lifecycle transition is not allowed.
class InvalidDisputeStateException implements Exception {
  const InvalidDisputeStateException();

  @override
  String toString() => 'InvalidDisputeStateException';
}

/// Thrown when the dispute subject is invalid.
class InvalidDisputeSubjectException implements Exception {
  const InvalidDisputeSubjectException({required this.message});

  final String message;

  @override
  String toString() => 'InvalidDisputeSubjectException';
}

/// Thrown when the dispute description is invalid.
class InvalidDisputeDescriptionException implements Exception {
  const InvalidDisputeDescriptionException({required this.message});

  final String message;

  @override
  String toString() => 'InvalidDisputeDescriptionException';
}

/// Thrown when the operational resolution note is invalid.
class InvalidDisputeResolutionException implements Exception {
  const InvalidDisputeResolutionException({required this.message});

  final String message;

  @override
  String toString() => 'InvalidDisputeResolutionException';
}

/// Thrown when a dispute category string is not an allowed enum value.
class InvalidDisputeCategoryException implements Exception {
  const InvalidDisputeCategoryException();

  @override
  String toString() => 'InvalidDisputeCategoryException';
}
