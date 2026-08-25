import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for payment attempts.
abstract class PaymentRepository {
  /// Finds a payment by id.
  Future<Payment?> findById(ObjectId id);

  /// Finds [id] only when owned by [customerUserId] and [bookingId].
  Future<Payment?> findForCustomerBooking({
    required ObjectId id,
    required ObjectId bookingId,
    required ObjectId customerUserId,
  });

  /// Lists all attempts for [bookingId], newest attempt first.
  Future<List<Payment>> listForBooking(ObjectId bookingId);

  /// Finds a payment by customer and client idempotency key.
  Future<Payment?> findByCustomerIdempotency({
    required ObjectId customerUserId,
    required String clientIdempotencyKey,
  });

  /// Finds a payment by provider and provider payment id.
  Future<Payment?> findByProviderPaymentId({
    required PaymentProviderType provider,
    required String providerPaymentId,
  });

  /// Active pending/authorized attempt for [bookingId], if any.
  Future<Payment?> findActiveForBooking(ObjectId bookingId);

  /// Successful settlement for [bookingId], if any.
  Future<Payment?> findSuccessfulForBooking(ObjectId bookingId);

  /// Next 1-based attempt number for [bookingId].
  Future<int> nextAttemptNumber(ObjectId bookingId);

  /// Inserts [payment]. Duplicate unique keys are reported.
  Future<Payment> create(Payment payment);

  /// Conditional pending → cancelled for the owning customer.
  Future<Payment?> cancelPending({
    required ObjectId id,
    required ObjectId customerUserId,
    required DateTime now,
  });

  /// Conditional pending/authorized → paid from a verified webhook.
  Future<Payment?> markPaidFromWebhook({
    required ObjectId id,
    required DateTime now,
  });

  /// Conditional pending/authorized → failed from a verified webhook.
  Future<Payment?> markFailedFromWebhook({
    required ObjectId id,
    required DateTime now,
    String? failureCode,
    String? failureMessage,
  });

  /// Conditional paid/partially_refunded refund application from a webhook.
  Future<Payment?> applyRefundFromWebhook({
    required ObjectId id,
    required int refundedAmountMinor,
    required bool fullRefund,
    required DateTime now,
  });

  /// Admin list page, `_id` descending, optional filters.
  Future<PaymentPage> adminPage({
    required int limit,
    PaymentStatus? status,
    PaymentProviderType? provider,
    String? currencyCode,
    ObjectId? bookingId,
    ObjectId? customerUserId,
    ObjectId? after,
  });

  /// Payments for many bookings. Used to avoid N+1 admin summaries.
  Future<List<Payment>> findByBookingIds(Iterable<ObjectId> ids);

  /// Count of payment documents for [customerUserId].
  Future<int> countForCustomer(ObjectId customerUserId);
}

/// MongoDB implementation of [PaymentRepository].
class MongoPaymentRepository implements PaymentRepository {
  /// Creates a repository over [documents].
  MongoPaymentRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the payments collection on [db].
  factory MongoPaymentRepository.fromDb(Db db) {
    return MongoPaymentRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.payments),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<Payment?> findById(ObjectId id) {
    return _find(<String, dynamic>{'_id': id});
  }

  @override
  Future<Payment?> findForCustomerBooking({
    required ObjectId id,
    required ObjectId bookingId,
    required ObjectId customerUserId,
  }) {
    return _find(<String, dynamic>{
      '_id': id,
      'booking_id': bookingId,
      'customer_user_id': customerUserId,
    });
  }

  @override
  Future<List<Payment>> listForBooking(ObjectId bookingId) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'booking_id': bookingId},
      sort: const <String, int>{'attempt_number': -1},
    );
    return documents.map(Payment.fromDocument).toList();
  }

  @override
  Future<Payment?> findByCustomerIdempotency({
    required ObjectId customerUserId,
    required String clientIdempotencyKey,
  }) {
    return _find(<String, dynamic>{
      'customer_user_id': customerUserId,
      'client_idempotency_key': clientIdempotencyKey,
    });
  }

  @override
  Future<Payment?> findByProviderPaymentId({
    required PaymentProviderType provider,
    required String providerPaymentId,
  }) {
    return _find(<String, dynamic>{
      'provider': provider.wireValue,
      'provider_payment_id': providerPaymentId,
    });
  }

  @override
  Future<Payment?> findActiveForBooking(ObjectId bookingId) {
    return _find(<String, dynamic>{
      'booking_id': bookingId,
      'payment_active': true,
    });
  }

  @override
  Future<Payment?> findSuccessfulForBooking(ObjectId bookingId) {
    return _find(<String, dynamic>{
      'booking_id': bookingId,
      'settlement_recorded': true,
    });
  }

  @override
  Future<int> nextAttemptNumber(ObjectId bookingId) async {
    final documents = await _documents.findMany(
      selector: <String, dynamic>{'booking_id': bookingId},
      sort: const <String, int>{'attempt_number': -1},
      limit: 1,
    );
    if (documents.isEmpty) {
      return 1;
    }
    return Payment.fromDocument(documents.first).attemptNumber + 1;
  }

  @override
  Future<Payment> create(Payment payment) async {
    final result = await _documents.insertOne(payment.toDocument());
    if (result.isDuplicateKey) {
      throw const PaymentDuplicateKeyException();
    }
    if (!result.isSuccess) {
      throw const PaymentWriteException();
    }
    return payment;
  }

  @override
  Future<Payment?> cancelPending({
    required ObjectId id,
    required ObjectId customerUserId,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'customer_user_id': customerUserId,
        'status': PaymentStatus.pending.wireValue,
        'payment_active': true,
      },
      set: <String, dynamic>{
        'status': PaymentStatus.cancelled.wireValue,
        'payment_active': false,
        'settlement_recorded': false,
        'cancelled_at': utc,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<Payment?> markPaidFromWebhook({
    required ObjectId id,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': <String, dynamic>{
          r'$in': <String>[
            PaymentStatus.pending.wireValue,
            PaymentStatus.authorized.wireValue,
          ],
        },
        'payment_active': true,
      },
      set: <String, dynamic>{
        'status': PaymentStatus.paid.wireValue,
        'payment_active': false,
        'settlement_recorded': true,
        'paid_at': utc,
        'failure_code': null,
        'failure_message': null,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<Payment?> markFailedFromWebhook({
    required ObjectId id,
    required DateTime now,
    String? failureCode,
    String? failureMessage,
  }) {
    final utc = now.toUtc();
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': <String, dynamic>{
          r'$in': <String>[
            PaymentStatus.pending.wireValue,
            PaymentStatus.authorized.wireValue,
          ],
        },
        'payment_active': true,
      },
      set: <String, dynamic>{
        'status': PaymentStatus.failed.wireValue,
        'payment_active': false,
        'settlement_recorded': false,
        'failed_at': utc,
        'failure_code': failureCode,
        'failure_message': failureMessage,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<Payment?> applyRefundFromWebhook({
    required ObjectId id,
    required int refundedAmountMinor,
    required bool fullRefund,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    final status = fullRefund
        ? PaymentStatus.refunded
        : PaymentStatus.partiallyRefunded;
    return _transition(
      selector: <String, dynamic>{
        '_id': id,
        'status': <String, dynamic>{
          r'$in': <String>[
            PaymentStatus.paid.wireValue,
            PaymentStatus.partiallyRefunded.wireValue,
          ],
        },
        'settlement_recorded': true,
      },
      set: <String, dynamic>{
        'status': status.wireValue,
        'payment_active': false,
        'settlement_recorded': true,
        'refunded_amount_minor': refundedAmountMinor,
        'refunded_at': utc,
        'updated_at': utc,
      },
    );
  }

  @override
  Future<PaymentPage> adminPage({
    required int limit,
    PaymentStatus? status,
    PaymentProviderType? provider,
    String? currencyCode,
    ObjectId? bookingId,
    ObjectId? customerUserId,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{};
    if (status != null) {
      selector['status'] = status.wireValue;
    }
    if (provider != null) {
      selector['provider'] = provider.wireValue;
    }
    if (currencyCode != null) {
      selector['currency_code'] = currencyCode;
    }
    if (bookingId != null) {
      selector['booking_id'] = bookingId;
    }
    if (customerUserId != null) {
      selector['customer_user_id'] = customerUserId;
    }
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
    final items = page.map(Payment.fromDocument).toList();
    return PaymentPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  @override
  Future<List<Payment>> findByBookingIds(Iterable<ObjectId> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) {
      return const <Payment>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'booking_id': <String, dynamic>{r'$in': unique},
      },
      sort: const <String, int>{'_id': -1},
    );
    return documents.map(Payment.fromDocument).toList();
  }

  @override
  Future<int> countForCustomer(ObjectId customerUserId) {
    return _documents.count(<String, dynamic>{
      'customer_user_id': customerUserId,
    });
  }

  Future<Payment?> _transition({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> set,
  }) async {
    final result = await _documents.updateOne(
      selector: selector,
      update: <String, dynamic>{r'$set': set},
    );
    if (!result.isSuccess && result.matched) {
      throw const PaymentWriteException();
    }
    if (!result.matched) {
      return null;
    }
    final id = selector['_id'];
    if (id is! ObjectId) {
      return null;
    }
    return _find(<String, dynamic>{'_id': id});
  }

  Future<Payment?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return Payment.fromDocument(document);
  }
}

/// Shared admin list pagination helper.
class PaymentAdminListQuery {
  /// Creates a validated list query.
  const PaymentAdminListQuery({
    required this.limit,
    this.status,
    this.provider,
    this.currencyCode,
    this.bookingId,
    this.customerUserId,
    this.after,
  });

  /// Parsed from HTTP query values.
  factory PaymentAdminListQuery.parse({
    Object? status,
    Object? provider,
    Object? currency,
    Object? bookingId,
    Object? customerUserId,
    Object? limitRaw,
    Object? after,
  }) {
    return PaymentAdminListQuery(
      status: PaymentValidation.optionalStatus(status),
      provider: PaymentValidation.optionalProvider(provider),
      currencyCode: PaymentValidation.optionalCurrency(currency),
      bookingId: PaymentValidation.optionalObjectId(
        bookingId,
        field: 'booking_id',
      ),
      customerUserId: PaymentValidation.optionalObjectId(
        customerUserId,
        field: 'customer_user_id',
      ),
      limit: PaymentValidation.requireLimit(limitRaw),
      after: PaymentValidation.optionalCursor(after),
    );
  }

  /// Optional status filter.
  final PaymentStatus? status;

  /// Optional provider filter.
  final PaymentProviderType? provider;

  /// Optional currency filter.
  final String? currencyCode;

  /// Optional booking filter.
  final ObjectId? bookingId;

  /// Optional customer filter.
  final ObjectId? customerUserId;

  /// Page size after validation.
  final int limit;

  /// Descending `_id` cursor, if any.
  final ObjectId? after;
}
