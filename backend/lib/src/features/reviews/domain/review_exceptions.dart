// ignore_for_file: public_member_api_docs
/// Thrown when a review document cannot be parsed.
class ReviewDocumentException implements Exception {
  const ReviewDocumentException(this.message);

  final String message;

  @override
  String toString() => 'ReviewDocumentException';
}

/// Thrown when a review write cannot be completed.
class ReviewWriteException implements Exception {
  const ReviewWriteException();

  @override
  String toString() => 'ReviewWriteException';
}

/// Thrown when a unique booking review index rejects an insert.
class ReviewDuplicateKeyException implements Exception {
  const ReviewDuplicateKeyException();

  @override
  String toString() => 'ReviewDuplicateKeyException';
}

/// Thrown when a review is missing or not visible to the caller.
class ReviewNotFoundException implements Exception {
  const ReviewNotFoundException();

  @override
  String toString() => 'ReviewNotFoundException';
}

/// Thrown when the booking is not eligible for review.
class ReviewNotAllowedException implements Exception {
  const ReviewNotAllowedException();

  @override
  String toString() => 'ReviewNotAllowedException';
}

/// Thrown when rating is not an integer 1–5.
class InvalidReviewRatingException implements Exception {
  const InvalidReviewRatingException();

  @override
  String toString() => 'InvalidReviewRatingException';
}

/// Thrown when a review comment is invalid.
class InvalidReviewCommentException implements Exception {
  const InvalidReviewCommentException({required this.message});

  final String message;

  @override
  String toString() => 'InvalidReviewCommentException';
}

/// Thrown when a hide reason is invalid.
class InvalidReviewReasonException implements Exception {
  const InvalidReviewReasonException({required this.message});

  final String message;

  @override
  String toString() => 'InvalidReviewReasonException';
}

/// Thrown when a moderation transition is not allowed.
class InvalidReviewStateException implements Exception {
  const InvalidReviewStateException();

  @override
  String toString() => 'InvalidReviewStateException';
}
