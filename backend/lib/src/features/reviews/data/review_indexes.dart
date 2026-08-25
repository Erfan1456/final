// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

const String reviewsBookingUniqueIndexName = 'reviews_booking_unique';
const String reviewsCleanerStatusIdDescIndexName =
    'reviews_cleaner_status_id_desc';
const String reviewsCustomerIdDescIndexName = 'reviews_customer_id_desc';
const String reviewsStatusRatingIdDescIndexName =
    'reviews_status_rating_id_desc';

const String reviewsBookingIdField = 'booking_id';
const String reviewsCleanerUserIdField = 'cleaner_user_id';
const String reviewsCustomerUserIdField = 'customer_user_id';
const String reviewsModerationStatusField = 'moderation_status';
const String reviewsRatingField = 'rating';

typedef EnsureReviewIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures `reviews` indexes used by customer, cleaner, admin, and discovery.
Future<void> ensureReviewIndexes({
  required EnsureReviewIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.reviews,
    keys: const <String, dynamic>{reviewsBookingIdField: 1},
    unique: true,
    name: reviewsBookingUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.reviews,
    keys: const <String, dynamic>{
      reviewsCleanerUserIdField: 1,
      reviewsModerationStatusField: 1,
      '_id': -1,
    },
    unique: false,
    name: reviewsCleanerStatusIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.reviews,
    keys: const <String, dynamic>{reviewsCustomerUserIdField: 1, '_id': -1},
    unique: false,
    name: reviewsCustomerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.reviews,
    keys: const <String, dynamic>{
      reviewsModerationStatusField: 1,
      reviewsRatingField: 1,
      '_id': -1,
    },
    unique: false,
    name: reviewsStatusRatingIdDescIndexName,
  );
}

/// Ensures review indexes on [db].
Future<void> ensureReviewIndexesOnDb(Db db) {
  return ensureReviewIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
        }) async {
          final collection = db.collection(collectionName);
          try {
            await collection.createIndex(
              keys: keys,
              unique: unique,
              name: name,
            );
          } catch (_) {
            final indexes = await collection.getIndexes();
            final exists = indexes.any((index) => index['name'] == name);
            if (!exists) {
              rethrow;
            }
          }
        },
  );
}
