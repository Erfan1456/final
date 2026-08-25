// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Admin review moderation.
class AdminReviewModerationService {
  AdminReviewModerationService({
    required ReviewRepository reviews,
    AuditSink? audit,
    DateTime Function()? clock,
  }) : _reviews = reviews,
       _audit = audit ?? const NoOpAuditSink(),
       _clock = clock ?? DateTime.now;

  final ReviewRepository _reviews;
  final AuditSink _audit;
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
      await _audit.appendBestEffort(
        actorUserId: user.id,
        actorRole: UserRole.admin,
        action: AuditAction.reviewHidden,
        targetType: AuditTargetType.review,
        targetId: hidden.id,
        reason: reason,
        metadata: <String, Object?>{
          'previous_status': ReviewModerationStatus.published.wireValue,
          'new_status': ReviewModerationStatus.hidden.wireValue,
        },
      );
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

  Future<Map<String, Object?>> unhide({
    required UserAccount user,
    required ObjectId reviewId,
  }) async {
    final published = await _reviews.unhideHidden(
      id: reviewId,
      now: _clock().toUtc(),
    );
    if (published != null) {
      await _audit.appendBestEffort(
        actorUserId: user.id,
        actorRole: UserRole.admin,
        action: AuditAction.reviewUnhidden,
        targetType: AuditTargetType.review,
        targetId: published.id,
        metadata: <String, Object?>{
          'previous_status': ReviewModerationStatus.hidden.wireValue,
          'new_status': ReviewModerationStatus.published.wireValue,
        },
      );
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
