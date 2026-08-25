import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique admin + idempotency key index.
const String paymentRefundAdminIdempotencyUniqueIndexName =
    'payment_refund_admin_idempotency_unique';

/// Payment refund history index (`created_at` descending).
const String paymentRefundPaymentCreatedIndexName =
    'payment_refund_payment_created';

/// Requesting user field.
const String paymentRefundAdminUserIdField = 'admin_user_id';

/// Idempotency key field.
const String paymentRefundIdempotencyKeyField = 'idempotency_key';

/// Payment id field.
const String paymentRefundPaymentIdField = 'payment_id';

/// Created-at field.
const String paymentRefundCreatedAtField = 'created_at';

/// Function used to ensure a refund-request index in tests.
typedef EnsurePaymentRefundRequestIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
    });

/// Ensures the approved `payment_refund_requests` indexes.
Future<void> ensurePaymentRefundRequestIndexes({
  required EnsurePaymentRefundRequestIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.paymentRefundRequests,
    keys: const <String, dynamic>{
      paymentRefundAdminUserIdField: 1,
      paymentRefundIdempotencyKeyField: 1,
    },
    unique: true,
    name: paymentRefundAdminIdempotencyUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.paymentRefundRequests,
    keys: const <String, dynamic>{
      paymentRefundPaymentIdField: 1,
      paymentRefundCreatedAtField: -1,
    },
    unique: false,
    name: paymentRefundPaymentCreatedIndexName,
  );
}

/// Ensures approved refund-request indexes on [db].
Future<void> ensurePaymentRefundRequestIndexesOnDb(Db db) {
  return ensurePaymentRefundRequestIndexes(
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
