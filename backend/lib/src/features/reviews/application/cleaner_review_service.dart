// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';

/// Cleaner list of own reviews.
class CleanerReviewService {
  CleanerReviewService({required ReviewRepository reviews})
    : _reviews = reviews;

  final ReviewRepository _reviews;

  Future<Map<String, Object?>> listOwnReviews({
    required UserAccount user,
    Object? status,
    Object? limitRaw,
    Object? after,
  }) async {
    final page = await _reviews.listForCleaner(
      cleanerUserId: user.id,
      limit: ReviewValidation.requireLimit(limitRaw),
      status: ReviewValidation.optionalStatus(status),
      after: ReviewValidation.optionalAfter(after),
    );
    return <String, Object?>{
      'items': [for (final item in page.items) item.toCleanerJson()],
      'next_cursor': page.nextCursor,
    };
  }
}
