/// Canonical MongoDB collection names used by this backend.
///
/// Add a name only when the corresponding collection is actually implemented.
abstract final class CollectionNames {
  /// Authentication identity collection.
  static const String users = 'users';

  /// Logical login/device refresh sessions.
  static const String userSessions = 'user_sessions';

  /// One customer marketplace profile per customer user.
  static const String customerProfiles = 'customer_profiles';

  /// Customer service addresses owned by a user.
  static const String addresses = 'addresses';

  /// One cleaner marketplace profile and current onboarding lifecycle.
  static const String cleanerProfiles = 'cleaner_profiles';

  /// Platform-owned service catalog definitions.
  static const String services = 'services';

  /// Cleaner offerings of platform services (pricing and activation).
  static const String cleanerServices = 'cleaner_services';

  /// Open future bookable availability windows for a cleaner and service.
  static const String availabilitySlots = 'availability_slots';

  /// Customer bookings of complete availability slots.
  static const String bookings = 'bookings';

  /// Authoritative payment attempts. Not a production processor ledger.
  static const String payments = 'payments';

  /// Idempotent provider webhook event receipts.
  static const String paymentWebhookEvents = 'payment_webhook_events';

  /// Idempotent admin/system refund commands.
  static const String paymentRefundRequests = 'payment_refund_requests';

  /// One booking-scoped customer/cleaner conversation.
  static const String conversations = 'conversations';

  /// Conversation participant read-cursor rows.
  static const String conversationMembers = 'conversation_members';

  /// Immutable booking-chat messages.
  static const String messages = 'messages';

  /// Persistent in-app notifications. Not push/email/SMS.
  static const String notifications = 'notifications';

  /// Verified completed-booking customer reviews.
  static const String reviews = 'reviews';

  /// Booking-scoped operational disputes. One document per booking.
  static const String disputes = 'disputes';

  /// Append-only administrative audit records.
  static const String auditLogs = 'audit_logs';
}
