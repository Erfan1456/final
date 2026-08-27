import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_log.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_address_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_service_snapshot.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_message.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/conversation.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/conversation_member.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_history_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_ledger_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/app_notification.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_event.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_webhook_processing_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_provider_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_request.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_event.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_webhook_processing_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/application/canonical_service_catalog.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_billing_model.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'demo_seed_constants.dart';
import 'demo_seed_integrity.dart';
import 'demo_seed_models.dart';
import 'demo_seed_plan.dart';

/// Manifest payload stored in [DemoSeedConstants.manifestCollection].
class DemoSeedManifestData {
  /// Creates manifest data without secrets.
  const DemoSeedManifestData({
    required this.seedKey,
    required this.collectionIds,
    required this.counts,
    required this.fingerprint,
    required this.createdAt,
  });

  final String seedKey;
  final Map<String, List<String>> collectionIds;
  final Map<String, int> counts;
  final String fingerprint;
  final DateTime createdAt;

  /// Parses a previously stored manifest document.
  factory DemoSeedManifestData.fromDocument(Map<String, dynamic> document) {
    final rawIds = document['collection_ids'];
    if (rawIds is! Map) {
      throw const FormatException('collection_ids must be a map');
    }
    final collectionIds = <String, List<String>>{};
    for (final entry in rawIds.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! List) {
        throw const FormatException('Invalid collection_ids entry');
      }
      collectionIds[key] = [
        for (final item in value) item.toString(),
      ];
    }
    final rawCounts = document['counts'];
    if (rawCounts is! Map) {
      throw const FormatException('counts must be a map');
    }
    final counts = <String, int>{};
    for (final entry in rawCounts.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! num) {
        throw const FormatException('Invalid counts entry');
      }
      counts[key] = value.toInt();
    }
    return DemoSeedManifestData(
      seedKey: document['seed_key'] as String,
      collectionIds: collectionIds,
      counts: counts,
      fingerprint: document['fingerprint'] as String,
      createdAt: (document['created_at'] as DateTime).toUtc(),
    );
  }

  /// Mongo document. Never includes passwords, hashes, or tokens.
  Map<String, dynamic> toDocument({required ObjectId id}) {
    return <String, dynamic>{
      '_id': id,
      'seed_key': seedKey,
      'collection_ids': {
        for (final entry in collectionIds.entries) entry.key: entry.value,
      },
      'counts': counts,
      'fingerprint': fingerprint,
      'created_at': createdAt.toUtc(),
    };
  }
}

/// Seed documents plus a secret-free manifest.
class DemoSeedBundle {
  /// Creates a bundle.
  const DemoSeedBundle({
    required this.documentsByCollection,
    required this.manifest,
  });

  final Map<String, List<Map<String, dynamic>>> documentsByCollection;
  final DemoSeedManifestData manifest;
}

/// Builds MongoDB documents for [plan] using supplied password hashes.
DemoSeedBundle buildDemoSeedDocuments({
  required DemoSeedPlan plan,
  required Map<String, String> passwordHashByEmailNormalized,
}) {
  final serviceSnapshot = const BookingServiceSnapshot(
    slug: CanonicalHomeCleaningService.slug,
    name: CanonicalHomeCleaningService.name,
    billingModel: ServiceBillingModel.hourly,
  );

  final users = <Map<String, dynamic>>[];
  for (final planned in plan.users) {
    final hash = passwordHashByEmailNormalized[planned.emailNormalized];
    if (hash == null || hash.isEmpty) {
      throw StateError('Missing password hash for seeded user');
    }
    if (!hash.startsWith(r'$argon2')) {
      throw StateError('password_hash must be argon2 encoded');
    }
    users.add(
      UserAccount(
        id: planned.id,
        role: planned.role,
        email: planned.email,
        emailNormalized: planned.emailNormalized,
        passwordHash: hash,
        accountStatus: planned.accountStatus,
        emailVerified: planned.emailVerified,
        createdAt: plan.nowUtc.subtract(const Duration(days: 40)),
        updatedAt: plan.nowUtc.subtract(const Duration(days: 1)),
      ).toDocument(),
    );
  }

  final customerProfiles = [
    for (final p in plan.customerProfiles)
      CustomerProfile(
        id: p.id,
        userId: p.userId,
        fullName: p.fullName,
        phoneE164: p.phoneE164,
        defaultAddressId: p.defaultAddressId,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      ).toDocument(),
  ];

  final cleanerProfiles = [
    for (final p in plan.cleanerProfiles)
      CleanerProfile(
        id: p.id,
        userId: p.userId,
        fullName: p.fullName,
        phoneE164: p.phoneE164,
        bio: p.bio,
        yearsExperience: p.yearsExperience,
        serviceArea: p.serviceArea,
        onboardingStatus: p.onboardingStatus,
        submittedAt: p.submittedAt,
        reviewedAt: p.reviewedAt,
        reviewedBy: p.reviewedBy,
        rejectionReason: p.rejectionReason,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      ).toDocument(),
  ];

  final addresses = [
    for (final a in plan.addresses)
      Address(
        id: a.id,
        userId: a.userId,
        label: a.label,
        line1: a.line1,
        line2: a.line2,
        city: a.city,
        region: a.region,
        postalCode: a.postalCode,
        countryCode: a.countryCode,
        createdAt: plan.nowUtc.subtract(const Duration(days: 30)),
        updatedAt: plan.nowUtc.subtract(const Duration(days: 2)),
      ).toDocument(),
  ];

  final offerings = [
    for (final o in plan.offerings)
      CleanerServiceOffering(
        id: o.id,
        cleanerUserId: o.cleanerUserId,
        serviceId: o.serviceId,
        hourlyRateMinor: o.hourlyRateMinor,
        currencyCode: o.currencyCode,
        isActive: o.isActive,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
      ).toDocument(),
  ];

  final slots = [
    for (final s in plan.availabilitySlots)
      AvailabilitySlot(
        id: s.id,
        cleanerUserId: s.cleanerUserId,
        serviceId: s.serviceId,
        startAt: s.startAt,
        endAt: s.endAt,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      ).toDocument(),
  ];

  final bookings = [
    for (final b in plan.bookings)
      Booking(
        id: b.id,
        customerUserId: b.customerUserId,
        cleanerUserId: b.cleanerUserId,
        availabilitySlotId: b.availabilitySlotId,
        serviceId: b.serviceId,
        status: b.status,
        reservationActive: b.reservationActive,
        durationMinutes: b.durationMinutes,
        hourlyRateMinor: b.hourlyRateMinor,
        quotedTotalMinor: b.quotedTotalMinor,
        currencyCode: b.currencyCode,
        serviceSnapshot: serviceSnapshot,
        addressSnapshot: BookingAddressSnapshot(
          label: b.address.label,
          line1: b.address.line1,
          line2: b.address.line2,
          city: b.address.city,
          region: b.address.region,
          postalCode: b.address.postalCode,
          countryCode: b.address.countryCode,
        ),
        customerNotes: b.customerNotes,
        idempotencyKey: b.idempotencyKey,
        requestFingerprint: _fingerprint(b.requestFingerprintSeed),
        startAt: b.startAt,
        endAt: b.endAt,
        acceptedAt: b.acceptedAt,
        declinedAt: b.declinedAt,
        startedAt: b.startedAt,
        completedAt: b.completedAt,
        cancelledAt: b.cancelledAt,
        statusHistory: _bookingHistory(b),
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      ).toDocument(),
  ];

  final payments = [
    for (final p in plan.payments)
      Payment(
        id: p.id,
        bookingId: p.bookingId,
        customerUserId: p.customerUserId,
        cleanerUserId: p.cleanerUserId,
        provider: PaymentProviderType.sandbox,
        status: p.status,
        amountMinor: p.amountMinor,
        currencyCode: p.currencyCode,
        attemptNumber: p.attemptNumber,
        clientIdempotencyKey: p.clientIdempotencyKey,
        requestFingerprint: _fingerprint(p.requestFingerprintSeed),
        paymentActive: p.paymentActive,
        settlementRecorded: p.settlementRecorded,
        providerPaymentId: p.providerPaymentId,
        providerReference: p.providerReference,
        failureCode: p.failureCode,
        failureMessage: p.failureMessage,
        authorizedAt: p.authorizedAt,
        paidAt: p.paidAt,
        failedAt: p.failedAt,
        cancelledAt: p.cancelledAt,
        refundedAt: p.refundedAt,
        refundedAmountMinor: p.refundedAmountMinor,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      ).toDocument(),
  ];

  final earnings = [
    for (final e in plan.earnings)
      EarningsLedgerEntry(
        id: e.id,
        cleanerUserId: e.cleanerUserId,
        bookingId: e.bookingId,
        paymentId: e.paymentId,
        entryType: EarningsEntryType.serviceEarning,
        grossAmountMinor: e.grossAmountMinor,
        commissionBps: e.commissionBps,
        platformFeeMinor: e.platformFeeMinor,
        cleanerAmountMinor: e.cleanerAmountMinor,
        currencyCode: e.currencyCode,
        sourceEventKey: e.sourceEventKey,
        createdAt: e.createdAt,
      ).toDocument(),
  ];

  final conversations = [
    for (final c in plan.conversations)
      Conversation(
        id: c.id,
        bookingId: c.bookingId,
        customerUserId: c.customerUserId,
        cleanerUserId: c.cleanerUserId,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        lastMessageAt: c.lastMessageAt,
      ).toDocument(),
  ];

  final members = [
    for (final m in plan.conversationMembers)
      ConversationMember(
        id: m.id,
        conversationId: m.conversationId,
        userId: m.userId,
        role: m.role,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      ).toDocument(),
  ];

  final messages = [
    for (final m in plan.messages)
      ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        senderUserId: m.senderUserId,
        senderRole: m.senderRole,
        body: m.body,
        clientIdempotencyKey: m.clientIdempotencyKey,
        createdAt: m.createdAt,
      ).toDocument(),
  ];

  final notifications = [
    for (final n in plan.notifications)
      AppNotification(
        id: n.id,
        userId: n.userId,
        type: NotificationType.fromWire(n.type),
        title: n.title,
        body: n.body,
        resourceType: n.resourceType,
        resourceId: n.resourceId,
        dedupeKey: n.dedupeKey,
        readAt: n.readAt,
        createdAt: n.createdAt,
      ).toDocument(),
  ];

  final reviews = [
    for (final r in plan.reviews)
      Review(
        id: r.id,
        bookingId: r.bookingId,
        customerUserId: r.customerUserId,
        cleanerUserId: r.cleanerUserId,
        rating: r.rating,
        comment: r.comment,
        moderationStatus: r.moderationStatus,
        hiddenReason: r.hiddenReason,
        hiddenBy: r.hiddenBy,
        hiddenAt: r.hiddenAt,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      ).toDocument(),
  ];

  final disputes = [
    for (final d in plan.disputes)
      Dispute(
        id: d.id,
        bookingId: d.bookingId,
        customerUserId: d.customerUserId,
        cleanerUserId: d.cleanerUserId,
        openedByUserId: d.openedByUserId,
        openedByRole: d.openedByRole,
        category: d.category,
        status: d.status,
        subject: d.subject,
        description: d.description,
        resolution: d.resolution,
        resolvedBy: d.resolvedBy,
        resolvedAt: d.resolvedAt,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        history: _disputeHistory(d),
      ).toDocument(),
  ];

  final auditLogs = [
    for (final a in plan.auditLogs)
      AuditLog(
        id: a.id,
        actorUserId: a.actorUserId,
        actorRole: a.actorRole,
        action: AuditAction.fromWire(a.action),
        targetType: a.targetType,
        targetId: a.targetId,
        reason: a.reason,
        createdAt: a.createdAt,
      ).toDocument(),
  ];

  final payouts = [
    for (final p in plan.payouts)
      PayoutRequest(
        id: p.id,
        cleanerUserId: p.cleanerUserId,
        amountMinor: p.amountMinor,
        currencyCode: p.currencyCode,
        status: p.status,
        attemptNumber: p.attemptNumber,
        clientIdempotencyKey: p.clientIdempotencyKey,
        requestFingerprint: _fingerprint(p.requestFingerprintSeed),
        payoutActive: p.payoutActive,
        provider: p.provider,
        providerPayoutId: p.providerPayoutId,
        requestedAt: p.requestedAt,
        processingAt: p.processingAt,
        paidAt: p.paidAt,
        failedAt: p.failedAt,
        failureCode: p.failureCode,
        failureMessage: p.failureMessage,
        processedBy: p.processedBy,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      ).toDocument(),
  ];

  final paymentWebhooks = [
    for (final w in plan.paymentWebhooks)
      PaymentWebhookEvent(
        id: w.id,
        provider: PaymentProviderType.sandbox,
        providerEventId: w.providerEventId,
        eventType: w.eventType,
        providerPaymentId: w.providerPaymentId,
        payloadSha256: _fingerprint(w.payloadSha256Seed),
        processingStatus: PaymentWebhookProcessingStatus.fromWire(
          w.processingStatus,
        ),
        processedAt: w.processedAt,
        createdAt: w.createdAt,
      ).toDocument(),
  ];

  final payoutWebhooks = [
    for (final w in plan.payoutWebhooks)
      PayoutProviderEvent(
        id: w.id,
        provider: PayoutProviderType.sandbox,
        providerEventId: w.providerEventId,
        eventType: w.eventType,
        providerPayoutId: w.providerPayoutId,
        payloadSha256: _fingerprint(w.payloadSha256Seed),
        processingStatus: PayoutWebhookProcessingStatus.fromWire(
          w.processingStatus,
        ),
        processedAt: w.processedAt,
        createdAt: w.createdAt,
      ).toDocument(),
  ];

  final documentsByCollection = <String, List<Map<String, dynamic>>>{
    CollectionNames.users: users,
    CollectionNames.customerProfiles: customerProfiles,
    CollectionNames.cleanerProfiles: cleanerProfiles,
    CollectionNames.addresses: addresses,
    CollectionNames.cleanerServices: offerings,
    CollectionNames.availabilitySlots: slots,
    CollectionNames.bookings: bookings,
    CollectionNames.payments: payments,
    CollectionNames.earningsLedger: earnings,
    CollectionNames.conversations: conversations,
    CollectionNames.conversationMembers: members,
    CollectionNames.messages: messages,
    CollectionNames.notifications: notifications,
    CollectionNames.reviews: reviews,
    CollectionNames.disputes: disputes,
    CollectionNames.auditLogs: auditLogs,
    CollectionNames.payoutRequests: payouts,
    CollectionNames.paymentWebhookEvents: paymentWebhooks,
    CollectionNames.payoutProviderEvents: payoutWebhooks,
  };

  DemoSeedIntegrity.assertDocumentsSafe(documentsByCollection);
  DemoSeedIntegrity.assertFinancialSplits(plan);

  final collectionIds = <String, List<String>>{
    for (final entry in documentsByCollection.entries)
      entry.key: [
        for (final doc in entry.value) (doc['_id'] as ObjectId).oid,
      ],
  };
  final counts = <String, int>{
    for (final entry in documentsByCollection.entries)
      entry.key: entry.value.length,
  };
  final fingerprintMaterial = jsonEncode({
    'seed_key': DemoSeedConstants.seedKey,
    'counts': counts,
    'collection_ids': collectionIds,
  });
  final manifest = DemoSeedManifestData(
    seedKey: DemoSeedConstants.seedKey,
    collectionIds: collectionIds,
    counts: counts,
    fingerprint: sha256.string(fingerprintMaterial, utf8).hex(),
    createdAt: plan.nowUtc,
  );

  return DemoSeedBundle(
    documentsByCollection: documentsByCollection,
    manifest: manifest,
  );
}

String _fingerprint(String seed) => sha256.string(seed, utf8).hex();

List<BookingStatusHistoryEntry> _bookingHistory(PlannedBooking booking) {
  final history = <BookingStatusHistoryEntry>[
    BookingStatusHistoryEntry(
      fromStatus: null,
      toStatus: BookingStatus.pending,
      actorUserId: booking.customerUserId,
      actorRole: UserRole.customer,
      createdAt: booking.createdAt,
    ),
  ];
  void add(
    BookingStatus from,
    BookingStatus to,
    ObjectId actor,
    UserRole role,
    DateTime at, [
    String? reason,
  ]) {
    history.add(
      BookingStatusHistoryEntry(
        fromStatus: from,
        toStatus: to,
        actorUserId: actor,
        actorRole: role,
        reason: reason,
        createdAt: at,
      ),
    );
  }

  switch (booking.status) {
    case BookingStatus.pending:
      break;
    case BookingStatus.confirmed:
      add(
        BookingStatus.pending,
        BookingStatus.confirmed,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.acceptedAt ?? booking.updatedAt,
      );
    case BookingStatus.inProgress:
      add(
        BookingStatus.pending,
        BookingStatus.confirmed,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.acceptedAt ?? booking.updatedAt,
      );
      add(
        BookingStatus.confirmed,
        BookingStatus.inProgress,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.startedAt ?? booking.updatedAt,
      );
    case BookingStatus.completed:
      add(
        BookingStatus.pending,
        BookingStatus.confirmed,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.acceptedAt ?? booking.updatedAt,
      );
      add(
        BookingStatus.confirmed,
        BookingStatus.inProgress,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.startedAt ?? booking.updatedAt,
      );
      add(
        BookingStatus.inProgress,
        BookingStatus.completed,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.completedAt ?? booking.updatedAt,
      );
    case BookingStatus.declined:
      add(
        BookingStatus.pending,
        BookingStatus.declined,
        booking.cleanerUserId,
        UserRole.cleaner,
        booking.declinedAt ?? booking.updatedAt,
        'Unavailable for this slot',
      );
    case BookingStatus.cancelled:
      add(
        BookingStatus.pending,
        BookingStatus.cancelled,
        booking.customerUserId,
        UserRole.customer,
        booking.cancelledAt ?? booking.updatedAt,
        'Customer cancelled',
      );
  }
  return history;
}

List<DisputeHistoryEntry> _disputeHistory(PlannedDispute dispute) {
  final history = <DisputeHistoryEntry>[
    DisputeHistoryEntry(
      fromStatus: null,
      toStatus: DisputeStatus.open,
      actorUserId: dispute.openedByUserId,
      actorRole: dispute.openedByRole,
      createdAt: dispute.createdAt,
    ),
  ];
  if (dispute.status == DisputeStatus.underReview ||
      dispute.status == DisputeStatus.resolved) {
    history.add(
      DisputeHistoryEntry(
        fromStatus: DisputeStatus.open,
        toStatus: DisputeStatus.underReview,
        actorUserId: dispute.resolvedBy ?? dispute.openedByUserId,
        actorRole: UserRole.admin,
        note: 'Admin started review',
        createdAt: dispute.updatedAt.subtract(const Duration(hours: 12)),
      ),
    );
  }
  if (dispute.status == DisputeStatus.resolved) {
    history.add(
      DisputeHistoryEntry(
        fromStatus: DisputeStatus.underReview,
        toStatus: DisputeStatus.resolved,
        actorUserId: dispute.resolvedBy!,
        actorRole: UserRole.admin,
        note: dispute.resolution,
        createdAt: dispute.resolvedAt ?? dispute.updatedAt,
      ),
    );
  }
  return history;
}
