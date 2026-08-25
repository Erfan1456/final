// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One page of reviews.
class ReviewPage {
  const ReviewPage({required this.items, required this.nextCursor});

  final List<Review> items;
  final String? nextCursor;
}

/// Persistence contract for verified booking reviews.
abstract class ReviewRepository {
  Future<Review?> findByBooking(ObjectId bookingId);

  Future<Review?> findById(ObjectId id);

  Future<Review> create(Review review);

  Future<Review?> updateCustomerReview({
    required ObjectId bookingId,
    required ObjectId customerUserId,
    required int rating,
    required String? comment,
    required DateTime now,
  });

  Future<ReviewPage> listForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
    ReviewModerationStatus? status,
    ObjectId? after,
  });

  Future<ReviewPage> adminPage({
    required int limit,
    ReviewModerationStatus? status,
    int? rating,
    ObjectId? cleanerUserId,
    ObjectId? after,
  });

  Future<Review?> hidePublished({
    required ObjectId id,
    required ObjectId adminUserId,
    required String reason,
    required DateTime now,
  });

  Future<Review?> unhideHidden({
    required ObjectId id,
    required DateTime now,
  });

  Future<Map<ObjectId, CleanerReviewAggregate>> aggregateForCleanerIds(
    Iterable<ObjectId> cleanerUserIds,
  );

  Future<List<Review>> latestPublishedForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
  });
}

/// MongoDB implementation of [ReviewRepository].
class MongoReviewRepository implements ReviewRepository {
  MongoReviewRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  factory MongoReviewRepository.fromDb(Db db) {
    return MongoReviewRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.reviews),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<Review?> findByBooking(ObjectId bookingId) {
    return _find(<String, dynamic>{'booking_id': bookingId});
  }

  @override
  Future<Review?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<Review> create(Review review) async {
    final result = await _documents.insertOne(review.toDocument());
    if (result.isDuplicateKey) {
      throw const ReviewDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const ReviewWriteException();
    }
    return review;
  }

  @override
  Future<Review?> updateCustomerReview({
    required ObjectId bookingId,
    required ObjectId customerUserId,
    required int rating,
    required String? comment,
    required DateTime now,
  }) async {
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        'booking_id': bookingId,
        'customer_user_id': customerUserId,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'rating': rating,
          'comment': comment,
          'updated_at': now.toUtc(),
        },
      },
    );
    if (!result.matched) {
      return null;
    }
    if (!result.isSuccess) {
      throw const ReviewWriteException();
    }
    return findByBooking(bookingId);
  }

  @override
  Future<ReviewPage> listForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
    ReviewModerationStatus? status,
    ObjectId? after,
  }) {
    final selector = <String, dynamic>{'cleaner_user_id': cleanerUserId};
    if (status != null) {
      selector['moderation_status'] = status.wireValue;
    }
    return _page(selector: selector, limit: limit, after: after);
  }

  @override
  Future<ReviewPage> adminPage({
    required int limit,
    ReviewModerationStatus? status,
    int? rating,
    ObjectId? cleanerUserId,
    ObjectId? after,
  }) {
    final selector = <String, dynamic>{};
    if (status != null) {
      selector['moderation_status'] = status.wireValue;
    }
    if (rating != null) {
      selector['rating'] = rating;
    }
    if (cleanerUserId != null) {
      selector['cleaner_user_id'] = cleanerUserId;
    }
    return _page(selector: selector, limit: limit, after: after);
  }

  @override
  Future<Review?> hidePublished({
    required ObjectId id,
    required ObjectId adminUserId,
    required String reason,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        '_id': id,
        'moderation_status': ReviewModerationStatus.published.wireValue,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'moderation_status': ReviewModerationStatus.hidden.wireValue,
          'hidden_reason': reason,
          'hidden_by': adminUserId,
          'hidden_at': utc,
          'updated_at': utc,
        },
      },
    );
    if (!result.matched) {
      return null;
    }
    if (!result.isSuccess) {
      throw const ReviewWriteException();
    }
    return findById(id);
  }

  @override
  Future<Review?> unhideHidden({
    required ObjectId id,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{
        '_id': id,
        'moderation_status': ReviewModerationStatus.hidden.wireValue,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'moderation_status': ReviewModerationStatus.published.wireValue,
          'updated_at': utc,
        },
        r'$unset': <String, dynamic>{
          'hidden_reason': '',
          'hidden_by': '',
          'hidden_at': '',
        },
      },
    );
    if (!result.matched) {
      return null;
    }
    if (!result.isSuccess) {
      throw const ReviewWriteException();
    }
    return findById(id);
  }

  @override
  Future<Map<ObjectId, CleanerReviewAggregate>> aggregateForCleanerIds(
    Iterable<ObjectId> cleanerUserIds,
  ) async {
    final ids = cleanerUserIds.toList();
    final aggregates = <ObjectId, CleanerReviewAggregate>{
      for (final id in ids)
        id: CleanerReviewAggregate(cleanerUserId: id, reviewCount: 0),
    };
    if (ids.isEmpty) {
      return aggregates;
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'cleaner_user_id': <String, dynamic>{r'$in': ids},
        'moderation_status': ReviewModerationStatus.published.wireValue,
      },
    );
    final sums = <ObjectId, int>{};
    final counts = <ObjectId, int>{};
    for (final document in documents) {
      final review = Review.fromDocument(document);
      sums[review.cleanerUserId] =
          (sums[review.cleanerUserId] ?? 0) + review.rating;
      counts[review.cleanerUserId] = (counts[review.cleanerUserId] ?? 0) + 1;
    }
    for (final id in ids) {
      final count = counts[id] ?? 0;
      final sum = sums[id] ?? 0;
      aggregates[id] = CleanerReviewAggregate(
        cleanerUserId: id,
        reviewCount: count,
        ratingAverage: count == 0 ? null : sum / count,
      );
    }
    return aggregates;
  }

  @override
  Future<List<Review>> latestPublishedForCleaner({
    required ObjectId cleanerUserId,
    required int limit,
  }) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'cleaner_user_id': cleanerUserId,
        'moderation_status': ReviewModerationStatus.published.wireValue,
      },
      sort: const <String, int>{'_id': -1},
      limit: limit,
    );
    return documents.map(Review.fromDocument).toList();
  }

  Future<ReviewPage> _page({
    required Map<String, dynamic> selector,
    required int limit,
    ObjectId? after,
  }) async {
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$lt': after};
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'_id': -1},
      limit: limit + 1,
    );
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;
    final items = page.map(Review.fromDocument).toList();
    return ReviewPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  Future<Review?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return Review.fromDocument(document);
  }
}
