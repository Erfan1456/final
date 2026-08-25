import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_refund_request_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_validation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/payment_test_fixtures.dart';

void main() {
  final customerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c1');
  final cleanerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c2');
  final bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');

  group('PaymentStatus', () {
    test('wire values and active/settlement mapping', () {
      expect(PaymentStatus.pending.wireValue, equals('pending'));
      expect(PaymentStatus.authorized.wireValue, equals('authorized'));
      expect(PaymentStatus.paid.wireValue, equals('paid'));
      expect(PaymentStatus.failed.wireValue, equals('failed'));
      expect(PaymentStatus.cancelled.wireValue, equals('cancelled'));
      expect(
        PaymentStatus.partiallyRefunded.wireValue,
        equals('partially_refunded'),
      );
      expect(PaymentStatus.refunded.wireValue, equals('refunded'));
      expect(PaymentStatus.pending.paymentActive, isTrue);
      expect(PaymentStatus.authorized.paymentActive, isTrue);
      expect(PaymentStatus.paid.paymentActive, isFalse);
      expect(PaymentStatus.paid.settlementRecorded, isTrue);
      expect(PaymentStatus.partiallyRefunded.settlementRecorded, isTrue);
      expect(PaymentStatus.refunded.settlementRecorded, isTrue);
      expect(PaymentStatus.failed.blocksNewCharge, isFalse);
      expect(PaymentStatus.cancelled.blocksNewCharge, isFalse);
      expect(PaymentStatus.paid.allowsRefund, isTrue);
      expect(
        PaymentStatus.fromWire('partially_refunded'),
        equals(PaymentStatus.partiallyRefunded),
      );
    });
  });

  group('PaymentProviderType', () {
    test('sandbox is the only TASK 016 wire value', () {
      expect(PaymentProviderType.sandbox.wireValue, equals('sandbox'));
      expect(
        PaymentProviderType.fromWire('sandbox'),
        equals(PaymentProviderType.sandbox),
      );
      expect(
        () => PaymentProviderType.fromWire('stripe'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Payment serialization', () {
    test('public JSON omits secrets, keys, fingerprints, and card fields', () {
      final payment = testPayment(
        bookingId: bookingId,
        customerId: customerId,
        cleanerId: cleanerId,
      );
      final json = payment.toPublicJson();
      expect(json['id'], equals(payment.id.oid));
      expect(json['amount_minor'], equals(500000));
      expect(json['currency_code'], equals('BDT'));
      expect(json.containsKey('client_idempotency_key'), isFalse);
      expect(json.containsKey('request_fingerprint'), isFalse);
      expect(json.containsKey('card_number'), isFalse);
      expect(json.containsKey('cvv'), isFalse);
      expect(json.toString(), isNot(contains(testSandboxWebhookSecret)));
      expect(payment.toDocument()['client_idempotency_key'], isNotNull);
    });

    test('remaining refundable is amount minus refunded', () {
      final payment = testPayment(
        bookingId: bookingId,
        customerId: customerId,
        cleanerId: cleanerId,
        status: PaymentStatus.partiallyRefunded,
        refundedAmountMinor: 100000,
      );
      expect(PaymentValidation.remainingRefundable(payment), equals(400000));
    });
  });

  group('payment indexes', () {
    test('requests approved unique and partial indexes', () async {
      final names = <String>[];
      Map<String, dynamic>? activePartial;
      Map<String, dynamic>? settlementPartial;
      await ensurePaymentIndexes(
        ensureIndex:
            ({
              required String collectionName,
              required Map<String, dynamic> keys,
              required bool unique,
              required String name,
              Map<String, dynamic>? partialFilterExpression,
            }) async {
              names.add(name);
              if (name == paymentsBookingActiveUniqueIndexName) {
                activePartial = partialFilterExpression;
                expect(unique, isTrue);
              }
              if (name == paymentsBookingSettlementUniqueIndexName) {
                settlementPartial = partialFilterExpression;
                expect(unique, isTrue);
              }
            },
      );
      expect(names, contains(paymentsProviderPaymentIdUniqueIndexName));
      expect(names, contains(paymentsCustomerIdempotencyUniqueIndexName));
      expect(names, contains(paymentsBookingAttemptUniqueIndexName));
      expect(names, contains(paymentsBookingIdDescIndexName));
      expect(names, contains(paymentsCustomerIdDescIndexName));
      expect(names, contains(paymentsStatusIdDescIndexName));
      expect(names, contains(paymentsBookingActiveUniqueIndexName));
      expect(names, contains(paymentsBookingSettlementUniqueIndexName));
      expect(
        activePartial,
        equals(const <String, dynamic>{'payment_active': true}),
      );
      expect(
        settlementPartial,
        equals(const <String, dynamic>{'settlement_recorded': true}),
      );
    });
  });

  group('webhook and refund indexes', () {
    test(
      'requests unique provider event and admin idempotency indexes',
      () async {
        final webhookNames = <String>[];
        await ensurePaymentWebhookEventIndexes(
          ensureIndex:
              ({
                required String collectionName,
                required Map<String, dynamic> keys,
                required bool unique,
                required String name,
              }) async {
                webhookNames.add(name);
              },
        );
        expect(
          webhookNames,
          contains(paymentWebhookEventsProviderEventUniqueIndexName),
        );
        final refundNames = <String>[];
        await ensurePaymentRefundRequestIndexes(
          ensureIndex:
              ({
                required String collectionName,
                required Map<String, dynamic> keys,
                required bool unique,
                required String name,
              }) async {
                refundNames.add(name);
              },
        );
        expect(
          refundNames,
          contains(paymentRefundAdminIdempotencyUniqueIndexName),
        );
      },
    );
  });
}
