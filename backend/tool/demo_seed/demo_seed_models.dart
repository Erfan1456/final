import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_category.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Planned seed user identity (no password material).
class PlannedUser {
  /// Creates a planned user.
  const PlannedUser({
    required this.id,
    required this.email,
    required this.emailNormalized,
    required this.fullName,
    required this.role,
    required this.accountStatus,
    required this.emailVerified,
    required this.isTargetAdmin,
    this.phoneE164,
  });

  final ObjectId id;
  final String email;
  final String emailNormalized;
  final String fullName;
  final UserRole role;
  final AccountStatus accountStatus;
  final bool emailVerified;
  final String? phoneE164;
  final bool isTargetAdmin;
}

/// Planned customer profile row.
class PlannedCustomerProfile {
  /// Creates a planned customer profile.
  const PlannedCustomerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.defaultAddressId,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
  });

  final ObjectId id;
  final ObjectId userId;
  final String fullName;
  final String? phoneE164;
  final ObjectId defaultAddressId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned cleaner profile row.
class PlannedCleanerProfile {
  /// Creates a planned cleaner profile.
  const PlannedCleanerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.bio,
    required this.yearsExperience,
    required this.serviceArea,
    required this.onboardingStatus,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final ObjectId id;
  final ObjectId userId;
  final String fullName;
  final String? phoneE164;
  final String bio;
  final int yearsExperience;
  final String serviceArea;
  final CleanerOnboardingStatus onboardingStatus;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final ObjectId? reviewedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned address row.
class PlannedAddress {
  /// Creates a planned address.
  const PlannedAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    this.line2,
  });

  final ObjectId id;
  final ObjectId userId;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String region;
  final String postalCode;
  final String countryCode;
}

/// Planned cleaner service offering.
class PlannedOffering {
  /// Creates a planned offering.
  const PlannedOffering({
    required this.id,
    required this.cleanerUserId,
    required this.serviceId,
    required this.hourlyRateMinor,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final ObjectId id;
  final ObjectId cleanerUserId;
  final ObjectId serviceId;
  final int hourlyRateMinor;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned availability slot.
class PlannedAvailabilitySlot {
  /// Creates a planned slot.
  const PlannedAvailabilitySlot({
    required this.id,
    required this.cleanerUserId,
    required this.serviceId,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final ObjectId id;
  final ObjectId cleanerUserId;
  final ObjectId serviceId;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned booking row.
class PlannedBooking {
  /// Creates a planned booking.
  const PlannedBooking({
    required this.id,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.availabilitySlotId,
    required this.serviceId,
    required this.status,
    required this.reservationActive,
    required this.durationMinutes,
    required this.hourlyRateMinor,
    required this.quotedTotalMinor,
    required this.currencyCode,
    required this.address,
    required this.idempotencyKey,
    required this.requestFingerprintSeed,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
    this.customerNotes,
    this.acceptedAt,
    this.declinedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  final ObjectId id;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final ObjectId availabilitySlotId;
  final ObjectId serviceId;
  final BookingStatus status;
  final bool reservationActive;
  final int durationMinutes;
  final int hourlyRateMinor;
  final int quotedTotalMinor;
  final String currencyCode;
  final PlannedAddress address;
  final String? customerNotes;
  final String idempotencyKey;
  final String requestFingerprintSeed;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned payment row.
class PlannedPayment {
  /// Creates a planned payment.
  const PlannedPayment({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.status,
    required this.amountMinor,
    required this.currencyCode,
    required this.attemptNumber,
    required this.clientIdempotencyKey,
    required this.requestFingerprintSeed,
    required this.paymentActive,
    required this.settlementRecorded,
    required this.refundedAmountMinor,
    required this.createdAt,
    required this.updatedAt,
    this.providerPaymentId,
    this.providerReference,
    this.failureCode,
    this.failureMessage,
    this.authorizedAt,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
  });

  final ObjectId id;
  final ObjectId bookingId;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final PaymentStatus status;
  final int amountMinor;
  final String currencyCode;
  final String? providerPaymentId;
  final String? providerReference;
  final int attemptNumber;
  final String clientIdempotencyKey;
  final String requestFingerprintSeed;
  final bool paymentActive;
  final bool settlementRecorded;
  final String? failureCode;
  final String? failureMessage;
  final DateTime? authorizedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final int refundedAmountMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned earnings ledger row.
class PlannedEarning {
  /// Creates a planned earning.
  const PlannedEarning({
    required this.id,
    required this.cleanerUserId,
    required this.bookingId,
    required this.paymentId,
    required this.grossAmountMinor,
    required this.commissionBps,
    required this.platformFeeMinor,
    required this.cleanerAmountMinor,
    required this.currencyCode,
    required this.sourceEventKey,
    required this.createdAt,
  });

  final ObjectId id;
  final ObjectId cleanerUserId;
  final ObjectId bookingId;
  final ObjectId paymentId;
  final int grossAmountMinor;
  final int commissionBps;
  final int platformFeeMinor;
  final int cleanerAmountMinor;
  final String currencyCode;
  final String sourceEventKey;
  final DateTime createdAt;
}

/// Planned review row.
class PlannedReview {
  /// Creates a planned review.
  const PlannedReview({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.rating,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    this.hiddenReason,
    this.hiddenBy,
    this.hiddenAt,
  });

  final ObjectId id;
  final ObjectId bookingId;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final int rating;
  final String? comment;
  final ReviewModerationStatus moderationStatus;
  final String? hiddenReason;
  final ObjectId? hiddenBy;
  final DateTime? hiddenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned dispute row.
class PlannedDispute {
  /// Creates a planned dispute.
  const PlannedDispute({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.openedByUserId,
    required this.openedByRole,
    required this.category,
    required this.status,
    required this.subject,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
  });

  final ObjectId id;
  final ObjectId bookingId;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final ObjectId openedByUserId;
  final UserRole openedByRole;
  final DisputeCategory category;
  final DisputeStatus status;
  final String subject;
  final String description;
  final String? resolution;
  final ObjectId? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned conversation row.
class PlannedConversation {
  /// Creates a planned conversation.
  const PlannedConversation({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.cleanerUserId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  final ObjectId id;
  final ObjectId bookingId;
  final ObjectId customerUserId;
  final ObjectId cleanerUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
}

/// Planned conversation member row.
class PlannedConversationMember {
  /// Creates a planned member.
  const PlannedConversationMember({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final ObjectId id;
  final ObjectId conversationId;
  final ObjectId userId;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned chat message row.
class PlannedMessage {
  /// Creates a planned message.
  const PlannedMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderRole,
    required this.body,
    required this.clientIdempotencyKey,
    required this.createdAt,
  });

  final ObjectId id;
  final ObjectId conversationId;
  final ObjectId senderUserId;
  final UserRole senderRole;
  final String body;
  final String clientIdempotencyKey;
  final DateTime createdAt;
}

/// Planned notification row.
class PlannedNotification {
  /// Creates a planned notification.
  const PlannedNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.dedupeKey,
    required this.createdAt,
    this.resourceType,
    this.resourceId,
    this.readAt,
  });

  final ObjectId id;
  final ObjectId userId;
  final String type;
  final String title;
  final String body;
  final String? resourceType;
  final ObjectId? resourceId;
  final String dedupeKey;
  final DateTime? readAt;
  final DateTime createdAt;
}

/// Planned audit log row.
class PlannedAuditLog {
  /// Creates a planned audit log.
  const PlannedAuditLog({
    required this.id,
    required this.actorUserId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.reason,
  });

  final ObjectId id;
  final ObjectId actorUserId;
  final UserRole actorRole;
  final String action;
  final String targetType;
  final ObjectId targetId;
  final String? reason;
  final DateTime createdAt;
}

/// Planned payout request row.
class PlannedPayout {
  /// Creates a planned payout.
  const PlannedPayout({
    required this.id,
    required this.cleanerUserId,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.attemptNumber,
    required this.clientIdempotencyKey,
    required this.requestFingerprintSeed,
    required this.payoutActive,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
    this.providerPayoutId,
    this.processingAt,
    this.paidAt,
    this.failedAt,
    this.failureCode,
    this.failureMessage,
    this.processedBy,
  });

  final ObjectId id;
  final ObjectId cleanerUserId;
  final int amountMinor;
  final String currencyCode;
  final PayoutStatus status;
  final int attemptNumber;
  final String clientIdempotencyKey;
  final String requestFingerprintSeed;
  final bool payoutActive;
  final String? provider;
  final String? providerPayoutId;
  final DateTime requestedAt;
  final DateTime? processingAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final String? failureCode;
  final String? failureMessage;
  final ObjectId? processedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Planned payment webhook event.
class PlannedPaymentWebhook {
  /// Creates a planned payment webhook.
  const PlannedPaymentWebhook({
    required this.id,
    required this.providerEventId,
    required this.eventType,
    required this.providerPaymentId,
    required this.payloadSha256Seed,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
  });

  final ObjectId id;
  final String providerEventId;
  final String eventType;
  final String providerPaymentId;
  final String payloadSha256Seed;
  final String processingStatus;
  final DateTime? processedAt;
  final DateTime createdAt;
}

/// Planned payout provider webhook event.
class PlannedPayoutWebhook {
  /// Creates a planned payout webhook.
  const PlannedPayoutWebhook({
    required this.id,
    required this.providerEventId,
    required this.eventType,
    required this.providerPayoutId,
    required this.payloadSha256Seed,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
  });

  final ObjectId id;
  final String providerEventId;
  final String eventType;
  final String providerPayoutId;
  final String payloadSha256Seed;
  final String processingStatus;
  final DateTime? processedAt;
  final DateTime createdAt;
}
