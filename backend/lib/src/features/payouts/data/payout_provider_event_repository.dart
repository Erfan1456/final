import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_processing_status.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for payout provider webhook event receipts.
abstract class PayoutProviderEventRepository {
  /// Finds a stored event by provider and provider event id.
  Future<PayoutProviderEvent?> findByProviderEventId({
    required PayoutProviderType provider,
    required String providerEventId,
  });

  /// Inserts a received event. Duplicate unique keys are reported.
  Future<PayoutProviderEvent> createReceived(PayoutProviderEvent event);

  /// Marks [id] processed.
  Future<PayoutProviderEvent?> markProcessed({
    required ObjectId id,
    required DateTime now,
  });

  /// Marks [id] ignored.
  Future<PayoutProviderEvent?> markIgnored({
    required ObjectId id,
    required DateTime now,
  });

  /// Marks [id] failed.
  Future<PayoutProviderEvent?> markFailed({
    required ObjectId id,
    required DateTime now,
  });

  /// Lists events for a provider payout id, newest first.
  Future<List<PayoutProviderEvent>> listForProviderPayoutId(
    String providerPayoutId,
  );
}

/// MongoDB implementation of [PayoutProviderEventRepository].
class MongoPayoutProviderEventRepository
    implements PayoutProviderEventRepository {
  /// Creates a repository over [documents].
  MongoPayoutProviderEventRepository({
    required CollectionDocumentStore documents,
  }) : _documents = documents;

  /// Creates a repository using the payout-events collection on [db].
  factory MongoPayoutProviderEventRepository.fromDb(Db db) {
    return MongoPayoutProviderEventRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.payoutProviderEvents),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<PayoutProviderEvent?> findByProviderEventId({
    required PayoutProviderType provider,
    required String providerEventId,
  }) {
    return _find(<String, dynamic>{
      'provider': provider.wireValue,
      'provider_event_id': providerEventId,
    });
  }

  @override
  Future<PayoutProviderEvent> createReceived(PayoutProviderEvent event) async {
    final result = await _documents.insertOne(event.toDocument());
    if (result.isDuplicateKey) {
      throw const PayoutDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const PayoutWriteException();
    }
    return event;
  }

  @override
  Future<PayoutProviderEvent?> markProcessed({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: PayoutWebhookProcessingStatus.processed,
      now: now,
    );
  }

  @override
  Future<PayoutProviderEvent?> markIgnored({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: PayoutWebhookProcessingStatus.ignored,
      now: now,
    );
  }

  @override
  Future<PayoutProviderEvent?> markFailed({
    required ObjectId id,
    required DateTime now,
  }) {
    return _markStatus(
      id: id,
      status: PayoutWebhookProcessingStatus.failed,
      now: now,
    );
  }

  @override
  Future<List<PayoutProviderEvent>> listForProviderPayoutId(
    String providerPayoutId,
  ) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'provider_payout_id': providerPayoutId},
      sort: const <String, int>{'created_at': -1},
    );
    return documents.map(PayoutProviderEvent.fromDocument).toList();
  }

  Future<PayoutProviderEvent?> _markStatus({
    required ObjectId id,
    required PayoutWebhookProcessingStatus status,
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
      throw const PayoutWriteException();
    }
    if (!result.matched) {
      return null;
    }
    return _find(<String, dynamic>{'_id': id});
  }

  Future<PayoutProviderEvent?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return PayoutProviderEvent.fromDocument(document);
  }
}
