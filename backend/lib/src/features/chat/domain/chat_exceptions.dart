// ignore_for_file: public_member_api_docs
/// Thrown when a conversation document cannot be parsed.
class ConversationDocumentException implements Exception {
  /// Creates a sanitized document-shape failure.
  const ConversationDocumentException(this.message);

  /// Safe diagnostic message.
  final String message;

  @override
  String toString() => 'ConversationDocumentException';
}

/// Thrown when a conversation write cannot be completed.
class ConversationWriteException implements Exception {
  const ConversationWriteException();

  @override
  String toString() => 'ConversationWriteException';
}

/// Thrown when a unique conversation index rejects an insert.
class ConversationDuplicateKeyException implements Exception {
  const ConversationDuplicateKeyException();

  @override
  String toString() => 'ConversationDuplicateKeyException';
}

/// Thrown when a conversation is missing or the caller is not a member.
class ConversationNotFoundException implements Exception {
  const ConversationNotFoundException();

  @override
  String toString() => 'ConversationNotFoundException';
}

/// Thrown when sending is blocked because the booking is terminal.
class ConversationReadOnlyException implements Exception {
  const ConversationReadOnlyException();

  @override
  String toString() => 'ConversationReadOnlyException';
}

/// Thrown when a message document cannot be parsed.
class MessageDocumentException implements Exception {
  const MessageDocumentException(this.message);

  /// Safe diagnostic message.
  final String message;

  @override
  String toString() => 'MessageDocumentException';
}

/// Thrown when a message write cannot be completed.
class MessageWriteException implements Exception {
  const MessageWriteException();

  @override
  String toString() => 'MessageWriteException';
}

/// Thrown when a unique message idempotency index rejects an insert.
class MessageDuplicateKeyException implements Exception {
  const MessageDuplicateKeyException();

  @override
  String toString() => 'MessageDuplicateKeyException';
}

/// Thrown when a message body is missing or invalid.
class InvalidMessageException implements Exception {
  const InvalidMessageException({required this.message});

  /// Safe client message.
  final String message;

  @override
  String toString() => 'InvalidMessageException';
}

/// Thrown when before and after cursors are both supplied.
class InvalidMessageCursorException implements Exception {
  const InvalidMessageCursorException();

  @override
  String toString() => 'InvalidMessageCursorException';
}

/// Thrown when a conversation member document cannot be parsed.
class ConversationMemberDocumentException implements Exception {
  const ConversationMemberDocumentException(this.message);

  /// Safe diagnostic message.
  final String message;

  @override
  String toString() => 'ConversationMemberDocumentException';
}

/// Thrown when a member write cannot be completed.
class ConversationMemberWriteException implements Exception {
  const ConversationMemberWriteException();

  @override
  String toString() => 'ConversationMemberWriteException';
}
