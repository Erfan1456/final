/// Result of inserting a document without exposing driver types.
class DocumentInsertResult {
  const DocumentInsertResult._({
    required this.isSuccess,
    required this.isDuplicateKey,
  });

  /// Insert acknowledged without write errors.
  const DocumentInsertResult.success()
    : this._(isSuccess: true, isDuplicateKey: false);

  /// Unique index rejected the insert (MongoDB code 11000).
  const DocumentInsertResult.duplicate()
    : this._(isSuccess: false, isDuplicateKey: true);

  /// Insert failed for a non-duplicate reason.
  const DocumentInsertResult.failed()
    : this._(isSuccess: false, isDuplicateKey: false);

  /// Whether the write completed successfully.
  final bool isSuccess;

  /// Whether the failure was a duplicate-key error.
  final bool isDuplicateKey;
}

/// Result of updating a document without exposing driver types.
class DocumentUpdateResult {
  const DocumentUpdateResult._({
    required this.isSuccess,
    required this.matched,
    required this.upserted,
  });

  /// Update acknowledged and matched one document.
  const DocumentUpdateResult.success()
    : this._(isSuccess: true, matched: true, upserted: false);

  /// Upsert inserted a new document.
  const DocumentUpdateResult.upserted()
    : this._(isSuccess: true, matched: false, upserted: true);

  /// Selector matched no document.
  const DocumentUpdateResult.notFound()
    : this._(isSuccess: false, matched: false, upserted: false);

  /// Update failed for a write or driver reason.
  const DocumentUpdateResult.failed()
    : this._(isSuccess: false, matched: false, upserted: false);

  /// Whether the write completed successfully.
  final bool isSuccess;

  /// Whether a document matched the selector.
  final bool matched;

  /// Whether a new document was inserted by upsert.
  final bool upserted;
}

/// Result of deleting a document without exposing driver types.
class DocumentDeleteResult {
  const DocumentDeleteResult._({
    required this.isSuccess,
    required this.deleted,
  });

  /// Delete acknowledged and removed one document.
  const DocumentDeleteResult.success() : this._(isSuccess: true, deleted: true);

  /// Selector matched no document.
  const DocumentDeleteResult.notFound()
    : this._(isSuccess: false, deleted: false);

  /// Delete failed for a write or driver reason.
  const DocumentDeleteResult.failed()
    : this._(isSuccess: false, deleted: false);

  /// Whether a document was deleted.
  final bool isSuccess;

  /// Whether a document was removed.
  final bool deleted;
}
