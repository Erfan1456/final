// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One verified customer review of a completed booking.
class Review {
  /// Creates a review.
  const Review({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.rating,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    this.hiddenReason,
    this.hiddenBy,
    this.hiddenAt,
  });

  /// Parses a MongoDB `reviews` document.
  factory Review.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => ReviewDocumentException(message);
    return Review(
      id: DocumentFields.requireObjectId(document, '_id', error),
      bookingId: DocumentFields.requireObjectId(document, 'booking_id', error),
      customerUserId: DocumentFields.requireObjectId(
        document,
        'customer_user_id',
        error,
      ),
      cleanerUserId: DocumentFields.requireObjectId(
        document,
        'cleaner_user_id',
        error,
      ),
      rating: DocumentFields.requireInt(document, 'rating', error),
      comment: DocumentFields.optionalString(document, 'comment', error),
      moderationStatus: ReviewModerationStatus.fromWire(
        DocumentFields.requireString(document, 'moderation_status', error),
      ),
      hiddenReason: DocumentFields.optionalString(
        document,
        'hidden_reason',
        error,
      ),
      hiddenBy: DocumentFields.optionalObjectId(document, 'hidden_by', error),
      hiddenAt: DocumentFields.optionalUtcDateTime(
        document,
        'hidden_at',
        error,
      ),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
      updatedAt: DocumentFields.requireUtcDateTime(
        document,
        'updated_at',
        error,
      ),
    );
  }

  final ObjectId id;
  final ObjectId bookingId;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final int rating;
  final String? comment;
  final ReviewModerationStatus moderationStatus;
  final String? hiddenReason;
  final ObjectId? hiddenBy;
  final DateTime? hiddenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'booking_id': bookingId,
      'customer_user_id': customerUserId,
      'cleaner_user_id': cleanerUserId,
      'rating': rating,
      'comment': comment,
      'moderation_status': moderationStatus.wireValue,
      'hidden_reason': hiddenReason,
      'hidden_by': hiddenBy,
      'hidden_at': hiddenAt?.toUtc(),
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Customer-owned review JSON, including moderation status.
  Map<String, Object?> toCustomerJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'rating': rating,
      'comment': comment,
      'moderation_status': moderationStatus.wireValue,
      'verified_booking': true,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Cleaner-owned review JSON. Reviewer is always "Verified customer".
  Map<String, Object?> toCleanerJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'rating': rating,
      'comment': comment,
      'moderation_status': moderationStatus.wireValue,
      'reviewer_display_name': 'Verified customer',
      'verified_booking': true,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Public discovery review. No customer ids or contact fields.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toUtc().toIso8601String(),
      'verified_booking': true,
      'reviewer_display_name': 'Verified customer',
    };
  }

  /// Admin moderation JSON. Includes ids needed to moderate.
  Map<String, Object?> toAdminJson() {
    return <String, Object?>{
      'id': id.oid,
      'booking_id': bookingId.oid,
      'customer_user_id': customerUserId.oid,
      'cleaner_user_id': cleanerUserId.oid,
      'rating': rating,
      'comment': comment,
      'moderation_status': moderationStatus.wireValue,
      'hidden_reason': hiddenReason,
      'hidden_by': hiddenBy?.oid,
      'hidden_at': hiddenAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}

/// Batched published-review aggregate for one cleaner.
class CleanerReviewAggregate {
  const CleanerReviewAggregate({
    required this.cleanerUserId,
    required this.reviewCount,
    this.ratingAverage,
  });

  final ObjectId cleanerUserId;
  final int reviewCount;
  final double? ratingAverage;
}
