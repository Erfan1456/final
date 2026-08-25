// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Admin review moderation.
class AdminReviewModerationService {
  AdminReviewModerationService({
    required ReviewRepository reviews,
    DateTime Function()? clock,
  }) : _reviews = reviews,
       _clock = clock ?? DateTime.now;

  final ReviewRepository _reviews;
  final DateTime Function() _clock;

  Future<Map<String, Object?>> list({
    Object? status,
    Object? rating,
    Object? cleanerUserId,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _reviews.adminPage(
      limit: ReviewValidation.requireLimit(limitRaw),
      status: ReviewValidation.optionalStatus(status),
      rating: ReviewValidation.optionalRatingFilter(rating),
      cleanerUserId: _optionalObjectId(cleanerUserId),
      after: ReviewValidation.optionalAfter(after),
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toAdminJson()],
      'next_cursor': page.nextCursor,
    };
  }

  Future<Map<String, Object?>> detail(ObjectId reviewId) async {
    final review = await _reviews.findById(reviewId);
    if (review == null) {
      throw const ReviewNotFoundException();
    }
    return review.toAdminJson();
  }

  Future<Map<String, Object?>> hide({
    required UserAccount user,
    required ObjectId reviewId,
    required Object? reasonRaw,
  }) async {
    final reason = ReviewValidation.requireReason(reasonRaw);
    final hidden = await _reviews.hidePublished(
      id: reviewId,
      adminUserId: user.id,
      reason: reason,
      now: _clock().toUtc(),
    );
    if (hidden != null) {
      return hidden.toAdminJson();
    }
    final existing = await _reviews.findById(reviewId);
    if (existing == null) {
      throw const ReviewNotFoundException();
    }
    if (existing.moderationStatus == ReviewModerationStatus.hidden) {
      return existing.toAdminJson();
    }
    throw const InvalidReviewStateException();
  }

  Future<Map<String, Object?>> unhide({required ObjectId reviewId}) async {
    final published = await _reviews.unhideHidden(
      id: reviewId,
      now: _clock().toUtc(),
    );
    if (published != null) {
      return published.toAdminJson();
    }
    final existing = await _reviews.findById(reviewId);
    if (existing == null) {
      throw const ReviewNotFoundException();
    }
    if (existing.moderationStatus == ReviewModerationStatus.published) {
      return existing.toAdminJson();
    }
    throw const InvalidReviewStateException();
  }

  ObjectId? _optionalObjectId(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return ObjectId.fromHexString(raw.trim());
      } catch (_) {
        throw const ReviewNotFoundException();
      }
    }
    throw const ReviewNotFoundException();
  }
}
