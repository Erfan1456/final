import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/database/database_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/data/audit_log_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_refund_request_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_provider_event_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';

/// Ensures approved MongoDB indexes. Prints only sanitized operational status.
///
/// Does not insert, update, delete, or dump application documents.
Future<void> main() async {
  final config = ServerConfig.fromEnvironment(const EnvironmentLoader().load());
  final mongo = MongoDatabase(config: config);

  if (!mongo.isConfigured) {
    stderr.writeln('Database indexes could not be ensured.');
    exitCode = 1;
    return;
  }

  try {
    await mongo.connect();
    final db = mongo.db;
    if (db == null) {
      stderr.writeln('Database indexes could not be ensured.');
      exitCode = 1;
      return;
    }

    await ensureApprovedDatabaseIndexes(db);
    final usersIndexes = await db
        .collection(CollectionNames.users)
        .getIndexes();
    final sessionIndexes = await db
        .collection(CollectionNames.userSessions)
        .getIndexes();
    final customerIndexes = await db
        .collection(CollectionNames.customerProfiles)
        .getIndexes();
    final cleanerIndexes = await db
        .collection(CollectionNames.cleanerProfiles)
        .getIndexes();
    final addressIndexes = await db
        .collection(CollectionNames.addresses)
        .getIndexes();
    final serviceIndexes = await db
        .collection(CollectionNames.services)
        .getIndexes();
    final offeringIndexes = await db
        .collection(CollectionNames.cleanerServices)
        .getIndexes();
    final slotIndexes = await db
        .collection(CollectionNames.availabilitySlots)
        .getIndexes();
    final bookingIndexes = await db
        .collection(CollectionNames.bookings)
        .getIndexes();
    final paymentIndexes = await db
        .collection(CollectionNames.payments)
        .getIndexes();
    final webhookIndexes = await db
        .collection(CollectionNames.paymentWebhookEvents)
        .getIndexes();
    final refundIndexes = await db
        .collection(CollectionNames.paymentRefundRequests)
        .getIndexes();
    final conversationIndexes = await db
        .collection(CollectionNames.conversations)
        .getIndexes();
    final conversationMemberIndexes = await db
        .collection(CollectionNames.conversationMembers)
        .getIndexes();
    final messageIndexes = await db
        .collection(CollectionNames.messages)
        .getIndexes();
    final notificationIndexes = await db
        .collection(CollectionNames.notifications)
        .getIndexes();
    final reviewIndexes = await db
        .collection(CollectionNames.reviews)
        .getIndexes();
    final disputeIndexes = await db
        .collection(CollectionNames.disputes)
        .getIndexes();
    final auditIndexes = await db
        .collection(CollectionNames.auditLogs)
        .getIndexes();
    final earningsIndexes = await db
        .collection(CollectionNames.earningsLedger)
        .getIndexes();
    final payoutIndexes = await db
        .collection(CollectionNames.payoutRequests)
        .getIndexes();
    final payoutEventIndexes = await db
        .collection(CollectionNames.payoutProviderEvents)
        .getIndexes();

    if (!_hasNamedIndex(usersIndexes, usersEmailNormalizedUniqueIndexName) ||
        !_hasNamedIndex(usersIndexes, usersRoleStatusIdDescIndexName) ||
        !_hasNamedIndex(
          sessionIndexes,
          userSessionsRefreshTokenHashUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          sessionIndexes,
          userSessionsUsedRefreshTokenHashesIndexName,
        ) ||
        !_hasNamedIndex(sessionIndexes, userSessionsUserIdIndexName) ||
        !_hasNamedIndex(sessionIndexes, userSessionsExpiresAtTtlIndexName) ||
        !_hasNamedIndex(
          customerIndexes,
          customerProfilesUserIdUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          cleanerIndexes,
          cleanerProfilesUserIdUniqueIndexName,
        ) ||
        !_hasNamedIndex(cleanerIndexes, cleanerProfilesStatusIdIndexName) ||
        !_hasNamedIndex(addressIndexes, addressesUserIdIndexName) ||
        !_hasNamedIndex(
          addressIndexes,
          addressesUserIdCreatedAtIndexName,
        ) ||
        !_hasNamedIndex(serviceIndexes, servicesSlugUniqueIndexName) ||
        !_hasNamedIndex(serviceIndexes, servicesActiveSlugIndexName) ||
        !_hasNamedIndex(
          offeringIndexes,
          cleanerServicesCleanerServiceUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          offeringIndexes,
          cleanerServicesServiceActiveIdIndexName,
        ) ||
        !_hasNamedIndex(
          offeringIndexes,
          cleanerServicesServiceCurrencyRateIdIndexName,
        ) ||
        !_hasNamedIndex(
          slotIndexes,
          availabilitySlotsCleanerStartUniqueIndexName,
        ) ||
        !_hasNamedIndex(slotIndexes, availabilitySlotsServiceStartIndexName) ||
        !_hasNamedIndex(
          slotIndexes,
          availabilitySlotsCleanerServiceStartIndexName,
        ) ||
        !_hasPartialUniqueActiveSlotIndex(bookingIndexes) ||
        !_hasNamedIndex(
          bookingIndexes,
          bookingsCustomerIdempotencyUniqueIndexName,
        ) ||
        !_hasNamedIndex(bookingIndexes, bookingsCustomerIdDescIndexName) ||
        !_hasNamedIndex(bookingIndexes, bookingsCleanerIdDescIndexName) ||
        !_hasNamedIndex(
          bookingIndexes,
          bookingsCleanerActiveStartIndexName,
        ) ||
        !_hasPartialUniqueActivePaymentIndex(paymentIndexes) ||
        !_hasPartialUniqueSettlementIndex(paymentIndexes) ||
        !_hasNamedIndex(
          paymentIndexes,
          paymentsProviderPaymentIdUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          paymentIndexes,
          paymentsCustomerIdempotencyUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          paymentIndexes,
          paymentsBookingAttemptUniqueIndexName,
        ) ||
        !_hasNamedIndex(paymentIndexes, paymentsBookingIdDescIndexName) ||
        !_hasNamedIndex(paymentIndexes, paymentsCustomerIdDescIndexName) ||
        !_hasNamedIndex(paymentIndexes, paymentsStatusIdDescIndexName) ||
        !_hasNamedIndex(
          webhookIndexes,
          paymentWebhookEventsProviderEventUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          webhookIndexes,
          paymentWebhookEventsPaymentCreatedIndexName,
        ) ||
        !_hasNamedIndex(
          refundIndexes,
          paymentRefundAdminIdempotencyUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          refundIndexes,
          paymentRefundPaymentCreatedIndexName,
        ) ||
        !_hasNamedIndex(
          conversationIndexes,
          conversationsBookingUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          conversationIndexes,
          conversationsCustomerLastMessageIndexName,
        ) ||
        !_hasNamedIndex(
          conversationIndexes,
          conversationsCleanerLastMessageIndexName,
        ) ||
        !_hasNamedIndex(
          conversationMemberIndexes,
          conversationMembersConversationUserUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          messageIndexes,
          messagesConversationIdDescIndexName,
        ) ||
        !_hasNamedIndex(
          messageIndexes,
          messagesSenderIdempotencyUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          notificationIndexes,
          notificationsUserIdDescIndexName,
        ) ||
        !_hasNamedIndex(
          notificationIndexes,
          notificationsUserReadIdDescIndexName,
        ) ||
        !_hasNamedIndex(
          notificationIndexes,
          notificationsUserDedupeUniqueIndexName,
        ) ||
        !_hasNamedIndex(reviewIndexes, reviewsBookingUniqueIndexName) ||
        !_hasNamedIndex(
          reviewIndexes,
          reviewsCleanerStatusIdDescIndexName,
        ) ||
        !_hasNamedIndex(reviewIndexes, reviewsCustomerIdDescIndexName) ||
        !_hasNamedIndex(
          reviewIndexes,
          reviewsStatusRatingIdDescIndexName,
        ) ||
        !_hasNamedIndex(disputeIndexes, disputesBookingUniqueIndexName) ||
        !_hasNamedIndex(disputeIndexes, disputesStatusIdDescIndexName) ||
        !_hasNamedIndex(disputeIndexes, disputesCustomerIdDescIndexName) ||
        !_hasNamedIndex(disputeIndexes, disputesCleanerIdDescIndexName) ||
        !_hasNamedIndex(
          disputeIndexes,
          disputesCategoryStatusIdDescIndexName,
        ) ||
        !_hasNamedIndex(auditIndexes, auditLogsActorIdDescIndexName) ||
        !_hasNamedIndex(auditIndexes, auditLogsActionIdDescIndexName) ||
        !_hasNamedIndex(auditIndexes, auditLogsTargetIdDescIndexName) ||
        !_hasNamedIndex(auditIndexes, auditLogsCreatedAtIndexName) ||
        !_hasNamedIndex(
          earningsIndexes,
          earningsLedgerSourceEventUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          earningsIndexes,
          earningsLedgerCleanerCurrencyIdDescIndexName,
        ) ||
        !_hasNamedIndex(earningsIndexes, earningsLedgerBookingTypeIndexName) ||
        !_hasNamedIndex(earningsIndexes, earningsLedgerCreatedAtIndexName) ||
        !_hasNamedIndex(
          payoutIndexes,
          payoutRequestsCleanerIdempotencyUniqueIndexName,
        ) ||
        !_hasPartialUniqueActivePayoutIndex(payoutIndexes) ||
        !_hasNamedIndex(payoutIndexes, payoutRequestsCleanerIdDescIndexName) ||
        !_hasNamedIndex(payoutIndexes, payoutRequestsStatusIdDescIndexName) ||
        !_hasPartialUniqueProviderPayoutIndex(payoutIndexes) ||
        !_hasNamedIndex(
          payoutEventIndexes,
          payoutEventsProviderEventUniqueIndexName,
        ) ||
        !_hasNamedIndex(
          payoutEventIndexes,
          payoutEventsProviderPayoutCreatedIndexName,
        )) {
      stderr.writeln('Database indexes could not be ensured.');
      exitCode = 1;
      return;
    }

    stdout
      ..writeln('Database indexes ensured successfully.')
      ..writeln('$usersEmailNormalizedUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $usersEmailNormalizedField ascending')
      ..writeln('$userSessionsRefreshTokenHashUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $userSessionsRefreshTokenHashField ascending')
      ..writeln('$userSessionsUsedRefreshTokenHashesIndexName exists')
      ..writeln('key = $userSessionsUsedRefreshTokenHashesField ascending')
      ..writeln('$userSessionsUserIdIndexName exists')
      ..writeln('key = $userSessionsUserIdField ascending')
      ..writeln('$userSessionsExpiresAtTtlIndexName exists')
      ..writeln('key = $userSessionsExpiresAtField ascending')
      ..writeln('expireAfterSeconds = 0')
      ..writeln('$customerProfilesUserIdUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $customerProfilesUserIdField ascending')
      ..writeln('$cleanerProfilesUserIdUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $cleanerProfilesUserIdField ascending')
      ..writeln('$cleanerProfilesStatusIdIndexName exists')
      ..writeln(
        'key = $cleanerProfilesOnboardingStatusField ascending, _id ascending',
      )
      ..writeln('$addressesUserIdIndexName exists')
      ..writeln('key = $addressesUserIdField ascending')
      ..writeln('$addressesUserIdCreatedAtIndexName exists')
      ..writeln(
        'key = $addressesUserIdField ascending, '
        '$addressesCreatedAtField descending',
      )
      ..writeln('$servicesSlugUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $servicesSlugField ascending')
      ..writeln('$servicesActiveSlugIndexName exists')
      ..writeln(
        'key = $servicesActiveField ascending, $servicesSlugField ascending',
      )
      ..writeln('$cleanerServicesCleanerServiceUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln(
        'key = $cleanerServicesCleanerUserIdField ascending, '
        '$cleanerServicesServiceIdField ascending',
      )
      ..writeln('$cleanerServicesServiceActiveIdIndexName exists')
      ..writeln('$cleanerServicesServiceCurrencyRateIdIndexName exists')
      ..writeln('$availabilitySlotsCleanerStartUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln(
        'key = $availabilitySlotsCleanerUserIdField ascending, '
        '$availabilitySlotsStartAtField ascending',
      )
      ..writeln('$availabilitySlotsServiceStartIndexName exists')
      ..writeln('$availabilitySlotsCleanerServiceStartIndexName exists')
      ..writeln('$bookingsActiveAvailabilitySlotUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('key = $bookingsAvailabilitySlotIdField ascending')
      ..writeln('partialFilterExpression.reservation_active = true')
      ..writeln('$bookingsCustomerIdempotencyUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$bookingsCustomerIdDescIndexName exists')
      ..writeln('$bookingsCleanerIdDescIndexName exists')
      ..writeln('$bookingsCleanerActiveStartIndexName exists')
      ..writeln('$paymentsProviderPaymentIdUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$paymentsCustomerIdempotencyUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$paymentsBookingAttemptUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$paymentsBookingIdDescIndexName exists')
      ..writeln('$paymentsCustomerIdDescIndexName exists')
      ..writeln('$paymentsStatusIdDescIndexName exists')
      ..writeln('$paymentsBookingActiveUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('partialFilterExpression.payment_active = true')
      ..writeln('$paymentsBookingSettlementUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('partialFilterExpression.settlement_recorded = true')
      ..writeln('$paymentWebhookEventsProviderEventUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$paymentWebhookEventsPaymentCreatedIndexName exists')
      ..writeln('$paymentRefundAdminIdempotencyUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$paymentRefundPaymentCreatedIndexName exists')
      ..writeln('$conversationsBookingUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$conversationsCustomerLastMessageIndexName exists')
      ..writeln('$conversationsCleanerLastMessageIndexName exists')
      ..writeln('$conversationMembersConversationUserUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$messagesConversationIdDescIndexName exists')
      ..writeln('$messagesSenderIdempotencyUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$notificationsUserIdDescIndexName exists')
      ..writeln('$notificationsUserReadIdDescIndexName exists')
      ..writeln('$notificationsUserDedupeUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$reviewsBookingUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$reviewsCleanerStatusIdDescIndexName exists')
      ..writeln('$reviewsCustomerIdDescIndexName exists')
      ..writeln('$reviewsStatusRatingIdDescIndexName exists')
      ..writeln('$usersRoleStatusIdDescIndexName exists')
      ..writeln('$disputesBookingUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$disputesStatusIdDescIndexName exists')
      ..writeln('$disputesCustomerIdDescIndexName exists')
      ..writeln('$disputesCleanerIdDescIndexName exists')
      ..writeln('$disputesCategoryStatusIdDescIndexName exists')
      ..writeln('$auditLogsActorIdDescIndexName exists')
      ..writeln('$auditLogsActionIdDescIndexName exists')
      ..writeln('$auditLogsTargetIdDescIndexName exists')
      ..writeln('$auditLogsCreatedAtIndexName exists')
      ..writeln('$earningsLedgerSourceEventUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$earningsLedgerCleanerCurrencyIdDescIndexName exists')
      ..writeln('$earningsLedgerBookingTypeIndexName exists')
      ..writeln('$earningsLedgerCreatedAtIndexName exists')
      ..writeln('$payoutRequestsCleanerIdempotencyUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$payoutRequestsCleanerActiveUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('partialFilterExpression.payout_active = true')
      ..writeln('$payoutRequestsCleanerIdDescIndexName exists')
      ..writeln('$payoutRequestsStatusIdDescIndexName exists')
      ..writeln('$payoutRequestsProviderPayoutUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$payoutEventsProviderEventUniqueIndexName exists')
      ..writeln('unique = true')
      ..writeln('$payoutEventsProviderPayoutCreatedIndexName exists');
  } catch (_) {
    stderr.writeln('Database indexes could not be ensured.');
    exitCode = 1;
  } finally {
    await mongo.close();
  }
}

bool _hasNamedIndex(List<Map<String, dynamic>> indexes, String name) {
  return indexes.any((index) => index['name'] == name);
}

bool _hasPartialUniqueActiveSlotIndex(List<Map<String, dynamic>> indexes) {
  for (final index in indexes) {
    if (index['name'] != bookingsActiveAvailabilitySlotUniqueIndexName) {
      continue;
    }
    if (index['unique'] != true) {
      return false;
    }
    final key = index['key'];
    if (key is! Map || key[bookingsAvailabilitySlotIdField] != 1) {
      return false;
    }
    final filter = index['partialFilterExpression'];
    if (filter is! Map || filter[bookingsReservationActiveField] != true) {
      return false;
    }
    return true;
  }
  return false;
}

bool _hasPartialUniqueActivePaymentIndex(List<Map<String, dynamic>> indexes) {
  for (final index in indexes) {
    if (index['name'] != paymentsBookingActiveUniqueIndexName) {
      continue;
    }
    if (index['unique'] != true) {
      return false;
    }
    final key = index['key'];
    if (key is! Map || key[paymentsBookingIdField] != 1) {
      return false;
    }
    final filter = index['partialFilterExpression'];
    if (filter is! Map || filter[paymentsPaymentActiveField] != true) {
      return false;
    }
    return true;
  }
  return false;
}

bool _hasPartialUniqueSettlementIndex(List<Map<String, dynamic>> indexes) {
  for (final index in indexes) {
    if (index['name'] != paymentsBookingSettlementUniqueIndexName) {
      continue;
    }
    if (index['unique'] != true) {
      return false;
    }
    final key = index['key'];
    if (key is! Map || key[paymentsBookingIdField] != 1) {
      return false;
    }
    final filter = index['partialFilterExpression'];
    if (filter is! Map || filter[paymentsSettlementRecordedField] != true) {
      return false;
    }
    return true;
  }
  return false;
}

bool _hasPartialUniqueActivePayoutIndex(List<Map<String, dynamic>> indexes) {
  for (final index in indexes) {
    if (index['name'] != payoutRequestsCleanerActiveUniqueIndexName) {
      continue;
    }
    if (index['unique'] != true) {
      return false;
    }
    final key = index['key'];
    if (key is! Map || key[payoutRequestsCleanerUserIdField] != 1) {
      return false;
    }
    final filter = index['partialFilterExpression'];
    if (filter is! Map || filter[payoutRequestsPayoutActiveField] != true) {
      return false;
    }
    return true;
  }
  return false;
}

bool _hasPartialUniqueProviderPayoutIndex(List<Map<String, dynamic>> indexes) {
  for (final index in indexes) {
    if (index['name'] != payoutRequestsProviderPayoutUniqueIndexName) {
      continue;
    }
    if (index['unique'] != true) {
      return false;
    }
    final key = index['key'];
    if (key is! Map ||
        key[payoutRequestsProviderField] != 1 ||
        key[payoutRequestsProviderPayoutIdField] != 1) {
      return false;
    }
    final filter = index['partialFilterExpression'];
    if (filter is! Map) {
      return false;
    }
    final type = filter[payoutRequestsProviderPayoutIdField];
    if (type is! Map || type[r'$type'] != 'string') {
      return false;
    }
    return true;
  }
  return false;
}
