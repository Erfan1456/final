import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_refund_request_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Deliberate database index initialization. Call once from a setup workflow,
/// not from per-request middleware.
Future<void> ensureApprovedDatabaseIndexes(Db db) async {
  await ensureUserIndexesOnDb(db);
  await ensureUserSessionIndexesOnDb(db);
  await ensureCustomerProfileIndexesOnDb(db);
  await ensureCleanerProfileIndexesOnDb(db);
  await ensureAddressIndexesOnDb(db);
  await ensureServiceIndexesOnDb(db);
  await ensureCleanerServiceIndexesOnDb(db);
  await ensureAvailabilityIndexesOnDb(db);
  await ensureBookingIndexesOnDb(db);
  await ensurePaymentIndexesOnDb(db);
  await ensurePaymentWebhookEventIndexesOnDb(db);
  await ensurePaymentRefundRequestIndexesOnDb(db);
  await ensureConversationIndexesOnDb(db);
  await ensureConversationMemberIndexesOnDb(db);
  await ensureMessageIndexesOnDb(db);
  await ensureNotificationIndexesOnDb(db);
  await ensureReviewIndexesOnDb(db);
}
