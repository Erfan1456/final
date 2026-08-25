import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_refund_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/refund_request_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for idempotent refund commands.
abstract class PaymentRefundRequestRepository {
  /// Finds a refund request by actor and idempotency key.
  Future<PaymentRefundRequest?> findByAdminIdempotency({
    required ObjectId adminUserId,
    required String idempotencyKey,
  });

  /// Inserts [request]. Duplicate unique keys are reported.
  Future<PaymentRefundRequest> create(PaymentRefundRequest request);

  /// Marks [id] succeeded.
  Future<PaymentRefundRequest?> markSucceeded({
    required ObjectId id,
    required DateTime now,
  });

  /// Marks [id] failed.
  Future<PaymentRefundRequest?> markFailed({
    required ObjectId id,
    required DateTime now,
  });
}

/// MongoDB implementation of [PaymentRefundRequestRepository].
class MongoPaymentRefundRequestRepository
    implements PaymentRefundRequestRepository {
  /// Creates a repository over [documents].
  MongoPaymentRefundRequestRepository({
    required CollectionDocumentStore documents,
  }) : _documents = documents;

  /// Creates a repository using the refund-requests collection on [db].
  factory MongoPaymentRefundRequestRepository.fromDb(Db db) {
    return MongoPaymentRefundRequestRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.paymentRefundRequests),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<PaymentRefundRequest?> findByAdminIdempotency({
    required ObjectId adminUserId,
    required String idempotencyKey,
  }) {
    return _find(<String, dynamic>{
      'admin_user_id': adminUserId,
      'idempotency_key': idempotencyKey,
    });
  }

  @override
  Future<PaymentRefundRequest> create(PaymentRefundRequest request) async {
    final result = await _documents.insertOne(request.toDocument());
    if (result.isDuplicateKey) {
      throw const PaymentDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const PaymentWriteException();
    }
    return request;
  }

  @override
  Future<PaymentRefundRequest?> markSucceeded({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: RefundRequestStatus.succeeded,
      now: now,
    );
  }

  @override
  Future<PaymentRefundRequest?> markFailed({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(id: id, status: RefundRequestStatus.failed, now: now);
  }

  Future<PaymentRefundRequest?> _markStatus({
    required ObjectId id,
    required RefundRequestStatus status,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'_id': id},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'status': status.wireValue,
          'updated_at': utc,
        },
      },
    );
    if (!result.isSuccess && result.matched) {
      throw const PaymentWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return _find(<String, dynamic>{'_id': id});
  }

  Future<PaymentRefundRequest?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return PaymentRefundRequest.fromDocument(document);
  }
}
