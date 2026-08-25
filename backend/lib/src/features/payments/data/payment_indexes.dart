import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Unique provider + provider_payment_id index.
const String paymentsProviderPaymentIdUniqueIndexName =
    'payments_provider_payment_id_unique';

/// Unique customer + client idempotency key index.
const String paymentsCustomerIdempotencyUniqueIndexName =
    'payments_customer_idempotency_unique';

/// Unique booking + attempt_number index.
const String paymentsBookingAttemptUniqueIndexName =
    'payments_booking_attempt_unique';

/// Booking list keyset index (`_id` descending).
const String paymentsBookingIdDescIndexName = 'payments_booking_id_desc';

/// Customer list keyset index (`_id` descending).
const String paymentsCustomerIdDescIndexName = 'payments_customer_id_desc';

/// Status list keyset index (`_id` descending).
const String paymentsStatusIdDescIndexName = 'payments_status_id_desc';

/// Partial unique active-payment index on booking_id.
const String paymentsBookingActiveUniqueIndexName =
    'payments_booking_active_unique';

/// Partial unique successful-settlement index on booking_id.
const String paymentsBookingSettlementUniqueIndexName =
    'payments_booking_settlement_unique';

/// Provider field.
const String paymentsProviderField = 'provider';

/// Provider payment id field.
const String paymentsProviderPaymentIdField = 'provider_payment_id';

/// Customer owner field.
const String paymentsCustomerUserIdField = 'customer_user_id';

/// Client idempotency key field.
const String paymentsClientIdempotencyKeyField = 'client_idempotency_key';

/// Booking owner field.
const String paymentsBookingIdField = 'booking_id';

/// Attempt number field.
const String paymentsAttemptNumberField = 'attempt_number';

/// Status field.
const String paymentsStatusField = 'status';

/// Explicit active-attempt concurrency field.
const String paymentsPaymentActiveField = 'payment_active';

/// Explicit successful-settlement uniqueness field.
const String paymentsSettlementRecordedField = 'settlement_recorded';

/// Function used to ensure a payment index without coupling tests to Atlas.
typedef EnsurePaymentIndexFn =
    Future<void> Function({
      required String collectionName,
      required Map<String, dynamic> keys,
      required bool unique,
      required String name,
      Map<String, dynamic>? partialFilterExpression,
    });

/// Ensures the approved `payments` indexes.
///
/// Active uniqueness uses `payment_active == true` rather than a `$in` status
/// partial filter. Atlas in this project already uses boolean partial unique
/// indexes (`reservation_active`). `settlement_recorded` prevents a second
/// successful payment per booking without a cross-document transaction.
Future<void> ensurePaymentIndexes({
  required EnsurePaymentIndexFn ensureIndex,
}) async {
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{
      paymentsProviderField: 1,
      paymentsProviderPaymentIdField: 1,
    },
    unique: true,
    name: paymentsProviderPaymentIdUniqueIndexName,
    partialFilterExpression: const <String, dynamic>{
      paymentsProviderPaymentIdField: <String, dynamic>{r'$type': 'string'},
    },
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{
      paymentsCustomerUserIdField: 1,
      paymentsClientIdempotencyKeyField: 1,
    },
    unique: true,
    name: paymentsCustomerIdempotencyUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{
      paymentsBookingIdField: 1,
      paymentsAttemptNumberField: 1,
    },
    unique: true,
    name: paymentsBookingAttemptUniqueIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{
      paymentsBookingIdField: 1,
      '_id': -1,
    },
    unique: false,
    name: paymentsBookingIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{
      paymentsCustomerUserIdField: 1,
      '_id': -1,
    },
    unique: false,
    name: paymentsCustomerIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{
      paymentsStatusField: 1,
      '_id': -1,
    },
    unique: false,
    name: paymentsStatusIdDescIndexName,
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{paymentsBookingIdField: 1},
    unique: true,
    name: paymentsBookingActiveUniqueIndexName,
    partialFilterExpression: const <String, dynamic>{
      paymentsPaymentActiveField: true,
    },
  );
  await ensureIndex(
    collectionName: CollectionNames.payments,
    keys: const <String, dynamic>{paymentsBookingIdField: 1},
    unique: true,
    name: paymentsBookingSettlementUniqueIndexName,
    partialFilterExpression: const <String, dynamic>{
      paymentsSettlementRecordedField: true,
    },
  );
}

/// Ensures approved payment indexes on [db], including partial unique.
Future<void> ensurePaymentIndexesOnDb(Db db) {
  return ensurePaymentIndexes(
    ensureIndex:
        ({
          required String collectionName,
          required Map<String, dynamic> keys,
          required bool unique,
          required String name,
          Map<String, dynamic>? partialFilterExpression,
        }) async {
          final collection = db.collection(collectionName);
          try {
            if (partialFilterExpression != null) {
              await db.runCommand(<String, Object>{
                'createIndexes': collectionName,
                'indexes': <Object>[
                  <String, Object>{
                    'key': Map<String, Object>.from(keys),
                    'name': name,
                    'unique': unique,
                    'partialFilterExpression': Map<String, Object>.from(
                      partialFilterExpression,
                    ),
                  },
                ],
              });
            } else {
              await collection.createIndex(
                keys: keys,
                unique: unique,
                name: name,
              );
            }
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
