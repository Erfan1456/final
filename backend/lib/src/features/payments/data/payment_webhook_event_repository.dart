import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_processing_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for provider webhook event receipts.
abstract class PaymentWebhookEventRepository {
  /// Finds a stored event by provider and provider event id.
  Future<PaymentWebhookEvent?> findByProviderEventId({
    required PaymentProviderType provider,
    required String providerEventId,
  });

  /// Inserts a received event. Duplicate unique keys are reported.
  Future<PaymentWebhookEvent> createReceived(PaymentWebhookEvent event);

  /// Marks [id] processed.
  Future<PaymentWebhookEvent?> markProcessed({
    required ObjectId id,
    required DateTime now,
  });

  /// Marks [id] ignored.
  Future<PaymentWebhookEvent?> markIgnored({
    required ObjectId id,
    required DateTime now,
  });

  /// Marks [id] failed.
  Future<PaymentWebhookEvent?> markFailed({
    required ObjectId id,
    required DateTime now,
  });

  /// Lists events for a provider payment id, newest first.
  Future<List<PaymentWebhookEvent>> listForProviderPaymentId(
    String providerPaymentId,
  );
}

/// MongoDB implementation of [PaymentWebhookEventRepository].
class MongoPaymentWebhookEventRepository
    implements PaymentWebhookEventRepository {
  /// Creates a repository over [documents].
  MongoPaymentWebhookEventRepository({
    required CollectionDocumentStore documents,
  }) : _documents = documents;

  /// Creates a repository using the webhook-events collection on [db].
  factory MongoPaymentWebhookEventRepository.fromDb(Db db) {
    return MongoPaymentWebhookEventRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.paymentWebhookEvents),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<PaymentWebhookEvent?> findByProviderEventId({
    required PaymentProviderType provider,
    required String providerEventId,
  }) {
    return _find(<String, dynamic>{
      'provider': provider.wireValue,
      'provider_event_id': providerEventId,
    });
  }

  @override
  Future<PaymentWebhookEvent> createReceived(PaymentWebhookEvent event) async {
    final result = await _documents.insertOne(event.toDocument());
    if (result.isDuplicateKey) {
      throw const PaymentDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const PaymentWriteException();
    }
    return event;
  }

  @override
  Future<PaymentWebhookEvent?> markProcessed({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: PaymentWebhookProcessingStatus.processed,
      now: now,
    );
  }

  @override
  Future<PaymentWebhookEvent?> markIgnored({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: PaymentWebhookProcessingStatus.ignored,
      now: now,
    );
  }

  @override
  Future<PaymentWebhookEvent?> markFailed({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: PaymentWebhookProcessingStatus.failed,
      now: now,
    );
  }

  @override
  Future<List<PaymentWebhookEvent>> listForProviderPaymentId(
    String providerPaymentId,
  ) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'provider_payment_id': providerPaymentId},
      sort: const <String, int>{'created_at': -1},
    );
    return documents.map(PaymentWebhookEvent.fromDocument).toList();
  }

  Future<PaymentWebhookEvent?> _markStatus({
    required ObjectId id,
    required PaymentWebhookProcessingStatus status,
    required DateTime now,
  }) async {
    final utc = now.toUtc();
    final result = await _documents.updateOne(
      selector: <String, dynamic>{'_id': id},
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'processing_status': status.wireValue,
          'processed_at': utc,
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

  Future<PaymentWebhookEvent?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return PaymentWebhookEvent.fromDocument(document);
  }
}
