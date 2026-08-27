import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_quotation.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_category.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/commission_math.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'demo_seed_constants.dart';
import 'demo_seed_models.dart';

/// Deterministic portfolio demo plan (no Mongo, no secrets).
class DemoSeedPlan {
  /// Creates a plan holding all planned seed rows.
  const DemoSeedPlan({
    required this.nowUtc,
    required this.serviceId,
    required this.commissionBps,
    required this.users,
    required this.customerProfiles,
    required this.cleanerProfiles,
    required this.addresses,
    required this.offerings,
    required this.availabilitySlots,
    required this.bookings,
    required this.payments,
    required this.earnings,
    required this.conversations,
    required this.conversationMembers,
    required this.messages,
    required this.notifications,
    required this.reviews,
    required this.disputes,
    required this.auditLogs,
    required this.payouts,
    required this.paymentWebhooks,
    required this.payoutWebhooks,
  });

  final DateTime nowUtc;
  final ObjectId serviceId;
  final int commissionBps;
  final List<PlannedUser> users;
  final List<PlannedCustomerProfile> customerProfiles;
  final List<PlannedCleanerProfile> cleanerProfiles;
  final List<PlannedAddress> addresses;
  final List<PlannedOffering> offerings;
  final List<PlannedAvailabilitySlot> availabilitySlots;
  final List<PlannedBooking> bookings;
  final List<PlannedPayment> payments;
  final List<PlannedEarning> earnings;
  final List<PlannedConversation> conversations;
  final List<PlannedConversationMember> conversationMembers;
  final List<PlannedMessage> messages;
  final List<PlannedNotification> notifications;
  final List<PlannedReview> reviews;
  final List<PlannedDispute> disputes;
  final List<PlannedAuditLog> auditLogs;
  final List<PlannedPayout> payouts;
  final List<PlannedPaymentWebhook> paymentWebhooks;
  final List<PlannedPayoutWebhook> payoutWebhooks;

  /// Target admin planned user.
  PlannedUser get targetAdmin => users.firstWhere((u) => u.isTargetAdmin);

  /// Role counts for customers / cleaners / admins.
  Map<UserRole, int> get roleCounts {
    final counts = <UserRole, int>{
      UserRole.customer: 0,
      UserRole.cleaner: 0,
      UserRole.admin: 0,
    };
    for (final user in users) {
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }
    return counts;
  }

  /// Booking status histogram.
  Map<BookingStatus, int> get bookingStatusCounts {
    final counts = <BookingStatus, int>{
      for (final status in BookingStatus.values) status: 0,
    };
    for (final booking in bookings) {
      counts[booking.status] = (counts[booking.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Compact counts for CLI / tests.
  Map<String, int> countSummary() {
    return <String, int>{
      'users': users.length,
      'customer_profiles': customerProfiles.length,
      'cleaner_profiles': cleanerProfiles.length,
      'addresses': addresses.length,
      'cleaner_services': offerings.length,
      'availability_slots': availabilitySlots.length,
      'bookings': bookings.length,
      'payments': payments.length,
      'earnings_ledger': earnings.length,
      'conversations': conversations.length,
      'conversation_members': conversationMembers.length,
      'messages': messages.length,
      'notifications': notifications.length,
      'reviews': reviews.length,
      'disputes': disputes.length,
      'audit_logs': auditLogs.length,
      'payout_requests': payouts.length,
      'payment_webhook_events': paymentWebhooks.length,
      'payout_provider_events': payoutWebhooks.length,
    };
  }

  /// Throws [StateError] when plan invariants fail.
  void validate() {
    if (users.length != 15) {
      throw StateError('Expected 15 users, got ${users.length}');
    }
    final roles = roleCounts;
    if (roles[UserRole.customer] != 6 ||
        roles[UserRole.cleaner] != 7 ||
        roles[UserRole.admin] != 2) {
      throw StateError('Unexpected role counts: $roles');
    }
    final emails = users.map((u) => u.emailNormalized).toSet();
    if (emails.length != users.length) {
      throw StateError('Duplicate normalized emails');
    }
    final nonExample = users.where(
      (u) => !u.emailNormalized.endsWith('@example.com'),
    );
    if (nonExample.length != 1 || !nonExample.first.isTargetAdmin) {
      throw StateError('Only target admin may use a non-example email');
    }
    if (addresses.length != 9) {
      throw StateError('Expected 9 addresses, got ${addresses.length}');
    }
    if (offerings.length != 5) {
      throw StateError('Expected 5 offerings, got ${offerings.length}');
    }
    final approvedCleanerIds = cleanerProfiles
        .where((p) => p.onboardingStatus == CleanerOnboardingStatus.approved)
        .map((p) => p.userId)
        .toSet();
    if (approvedCleanerIds.length != 5) {
      throw StateError('Expected 5 approved cleaners');
    }
    for (final cleanerId in approvedCleanerIds) {
      final offeringCount = offerings
          .where((o) => o.cleanerUserId == cleanerId)
          .length;
      if (offeringCount != 1) {
        throw StateError(
          'Expected 1 offering per approved cleaner, got $offeringCount',
        );
      }
    }

    final bookedSlotIds = bookings.map((b) => b.availabilitySlotId).toSet();
    for (final cleanerId in approvedCleanerIds) {
      final openFuture = availabilitySlots.where(
        (s) =>
            s.cleanerUserId == cleanerId &&
            s.startAt.isAfter(nowUtc) &&
            !bookedSlotIds.contains(s.id),
      );
      if (openFuture.length < 4) {
        throw StateError(
          'Approved cleaner needs >=4 open future slots, got '
          '${openFuture.length}',
        );
      }
    }

    if (bookings.length != 14) {
      throw StateError('Expected 14 bookings, got ${bookings.length}');
    }
    final statusCounts = bookingStatusCounts;
    if (statusCounts[BookingStatus.pending] != 2 ||
        statusCounts[BookingStatus.confirmed] != 2 ||
        statusCounts[BookingStatus.inProgress] != 1 ||
        statusCounts[BookingStatus.completed] != 5 ||
        statusCounts[BookingStatus.declined] != 2 ||
        statusCounts[BookingStatus.cancelled] != 2) {
      throw StateError('Unexpected booking status counts: $statusCounts');
    }

    final activeSlotIds = <ObjectId>{};
    for (final booking in bookings) {
      if (booking.reservationActive != booking.status.reservationActive) {
        throw StateError('reservation_active mismatch for ${booking.id.oid}');
      }
      final expectedQuote = BookingQuotation.quotedTotalMinor(
        hourlyRateMinor: booking.hourlyRateMinor,
        durationMinutes: booking.durationMinutes,
      );
      if (booking.quotedTotalMinor != expectedQuote) {
        throw StateError('quoted_total_minor mismatch for ${booking.id.oid}');
      }
      if (booking.reservationActive) {
        if (!activeSlotIds.add(booking.availabilitySlotId)) {
          throw StateError('Duplicate active reservation slot');
        }
      }
    }

    for (final payment in payments) {
      if (payment.paymentActive != payment.status.paymentActive) {
        throw StateError('payment_active mismatch for ${payment.id.oid}');
      }
      if (payment.settlementRecorded != payment.status.settlementRecorded) {
        throw StateError('settlement_recorded mismatch for ${payment.id.oid}');
      }
    }

    if (earnings.length < 5) {
      throw StateError('Expected >=5 earnings, got ${earnings.length}');
    }
    for (final earning in earnings) {
      final fee = CommissionMath.platformFeeMinor(
        grossMinor: earning.grossAmountMinor,
        commissionBps: earning.commissionBps,
      );
      final net = CommissionMath.cleanerNetMinor(
        grossMinor: earning.grossAmountMinor,
        commissionBps: earning.commissionBps,
      );
      if (earning.platformFeeMinor != fee ||
          earning.cleanerAmountMinor != net ||
          earning.platformFeeMinor + earning.cleanerAmountMinor !=
              earning.grossAmountMinor) {
        throw StateError('Earnings split invalid for ${earning.id.oid}');
      }
      if (!earning.sourceEventKey.startsWith('earning:booking:')) {
        throw StateError('Invalid earning source_event_key');
      }
    }

    if (conversations.length != 8) {
      throw StateError('Expected 8 conversations, got ${conversations.length}');
    }
    if (messages.length < 28 || messages.length > 40) {
      throw StateError('Expected ~32 messages, got ${messages.length}');
    }
    if (notifications.length < 25 || notifications.length > 35) {
      throw StateError(
        'Expected 25-35 notifications, got ${notifications.length}',
      );
    }
    if (reviews.length != 5) {
      throw StateError('Expected 5 reviews, got ${reviews.length}');
    }
    final published = reviews
        .where((r) => r.moderationStatus == ReviewModerationStatus.published)
        .length;
    final hidden = reviews
        .where((r) => r.moderationStatus == ReviewModerationStatus.hidden)
        .length;
    if (published != 4 || hidden != 1) {
      throw StateError('Expected 4 published and 1 hidden review');
    }
    final completedIds = bookings
        .where((b) => b.status == BookingStatus.completed)
        .map((b) => b.id)
        .toSet();
    for (final review in reviews) {
      if (!completedIds.contains(review.bookingId)) {
        throw StateError('Review must reference a completed booking');
      }
    }
    if (disputes.length != 3) {
      throw StateError('Expected 3 disputes, got ${disputes.length}');
    }
    final disputeStatuses = disputes.map((d) => d.status).toSet();
    if (!disputeStatuses.contains(DisputeStatus.open) ||
        !disputeStatuses.contains(DisputeStatus.underReview) ||
        !disputeStatuses.contains(DisputeStatus.resolved)) {
      throw StateError('Disputes must include open/under_review/resolved');
    }
    if (auditLogs.length < 8 || auditLogs.length > 12) {
      throw StateError('Expected 8-12 audit logs, got ${auditLogs.length}');
    }
    if (payouts.length != 4) {
      throw StateError('Expected 4 payouts, got ${payouts.length}');
    }
    final payoutStatuses = payouts.map((p) => p.status).toSet();
    if (payoutStatuses.length < 4) {
      throw StateError('Expected 4 distinct payout statuses');
    }
    for (final payout in payouts) {
      if (payout.payoutActive != payout.status.payoutActive) {
        throw StateError('payout_active mismatch for ${payout.id.oid}');
      }
    }
  }
}

/// Builds the fixed portfolio demo plan relative to [nowUtc].
DemoSeedPlan buildDemoSeedPlan({
  required DateTime nowUtc,
  required ObjectId serviceId,
  required int commissionBps,
}) {
  final now = nowUtc.toUtc();

  final customers = <PlannedUser>[
    _customer(
      1,
      'Amina Rahman',
      'customer01@example.com',
      AccountStatus.active,
    ),
    _customer(2, 'Nafis Ahmed', 'customer02@example.com', AccountStatus.active),
    _customer(
      3,
      'Tasnia Islam',
      'customer03@example.com',
      AccountStatus.active,
    ),
    _customer(
      4,
      'Farhan Chowdhury',
      'customer04@example.com',
      AccountStatus.active,
    ),
    _customer(5, 'Maya Hasan', 'customer05@example.com', AccountStatus.active),
    _customer(
      6,
      'Rafi Karim',
      'customer06@example.com',
      AccountStatus.suspended,
    ),
  ];

  final cleaners = <PlannedUser>[
    _cleaner(7, 'Salma Akter', 'cleaner01@example.com'),
    _cleaner(8, 'Jahid Hasan', 'cleaner02@example.com'),
    _cleaner(9, 'Nusrat Jahan', 'cleaner03@example.com'),
    _cleaner(10, 'Rashed Ali', 'cleaner04@example.com'),
    _cleaner(11, 'Tania Sultana', 'cleaner05@example.com'),
    _cleaner(12, 'Mehedi Rahman', 'cleaner06@example.com'),
    _cleaner(13, 'Sharmin Begum', 'cleaner07@example.com'),
  ];

  final targetAdmin = PlannedUser(
    id: DemoSeedConstants.id(DemoSeedIdPrefix.users, 14),
    email: DemoSeedConstants.targetAdminEmail,
    emailNormalized: DemoSeedConstants.targetAdminEmailNormalized,
    fullName: 'Erfan Khan',
    role: UserRole.admin,
    accountStatus: AccountStatus.active,
    emailVerified: true,
    phoneE164: '+8801700000014',
    isTargetAdmin: true,
  );
  final demoAdmin = PlannedUser(
    id: DemoSeedConstants.id(DemoSeedIdPrefix.users, 15),
    email: DemoSeedConstants.demoAdminEmail,
    emailNormalized: DemoSeedConstants.demoAdminEmail,
    fullName: 'Demo Admin',
    role: UserRole.admin,
    accountStatus: AccountStatus.active,
    emailVerified: true,
    phoneE164: '+8801700000015',
    isTargetAdmin: false,
  );

  final users = <PlannedUser>[
    ...customers,
    ...cleaners,
    targetAdmin,
    demoAdmin,
  ];

  final addressSpecs = <({int userIndex, String label, String line1})>[
    (userIndex: 1, label: 'Home', line1: '12 Gulshan Avenue'),
    (userIndex: 1, label: 'Office', line1: '45 Banani Road'),
    (userIndex: 2, label: 'Home', line1: '88 Dhanmondi 27'),
    (userIndex: 2, label: 'Parents', line1: '3 Mirpur DOHS'),
    (userIndex: 3, label: 'Home', line1: '19 Uttara Sector 7'),
    (userIndex: 3, label: 'Apartment', line1: '61 Bashundhara R/A'),
    (userIndex: 4, label: 'Home', line1: '7 Mohammadpur'),
    (userIndex: 5, label: 'Home', line1: '22 Tejgaon Industrial'),
    (userIndex: 6, label: 'Home', line1: '9 Motijheel C/A'),
  ];

  final addresses = <PlannedAddress>[
    for (var i = 0; i < addressSpecs.length; i++)
      PlannedAddress(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.addresses, i + 1),
        userId: DemoSeedConstants.id(
          DemoSeedIdPrefix.users,
          addressSpecs[i].userIndex,
        ),
        label: addressSpecs[i].label,
        line1: addressSpecs[i].line1,
        line2: i.isEven ? 'Apt ${i + 1}' : null,
        city: 'Dhaka',
        region: 'Dhaka Division',
        postalCode: '12${(i + 10).toString().padLeft(2, '0')}',
        countryCode: 'BD',
      ),
  ];

  ObjectId defaultAddressFor(int userIndex) {
    return addresses.firstWhere((a) => a.userId == _uid(userIndex)).id;
  }

  final customerProfiles = <PlannedCustomerProfile>[
    for (var i = 1; i <= 6; i++)
      PlannedCustomerProfile(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.customerProfiles, i),
        userId: _uid(i),
        fullName: customers[i - 1].fullName,
        phoneE164: customers[i - 1].phoneE164,
        defaultAddressId: defaultAddressFor(i),
        createdAt: now.subtract(Duration(days: 40 - i)),
        updatedAt: now.subtract(Duration(days: 10 - i)),
      ),
  ];

  final cleanerBios = <String>[
    'Experienced home cleaner focused on kitchens and bathrooms.',
    'Reliable weekly cleaning with attention to living spaces.',
    'Detail-oriented cleaner for apartments and family homes.',
    'Professional cleaner covering Dhaka north residential areas.',
    'Trusted cleaner specializing in move-in and deep cleans.',
    'New cleaner applicant preparing residential service coverage.',
    'Applicant with mixed experience seeking platform approval.',
  ];
  final onboarding = <CleanerOnboardingStatus>[
    CleanerOnboardingStatus.approved,
    CleanerOnboardingStatus.approved,
    CleanerOnboardingStatus.approved,
    CleanerOnboardingStatus.approved,
    CleanerOnboardingStatus.approved,
    CleanerOnboardingStatus.pending,
    CleanerOnboardingStatus.rejected,
  ];

  final cleanerProfiles = <PlannedCleanerProfile>[
    for (var i = 0; i < 7; i++)
      PlannedCleanerProfile(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.cleanerProfiles, i + 1),
        userId: _uid(7 + i),
        fullName: cleaners[i].fullName,
        phoneE164: cleaners[i].phoneE164,
        bio: cleanerBios[i],
        yearsExperience: 2 + i,
        serviceArea:
            'Dhaka ${['North', 'South', 'East', 'West', 'Central', 'Uttara', 'Mirpur'][i]}',
        onboardingStatus: onboarding[i],
        submittedAt: now.subtract(Duration(days: 20 - i)),
        reviewedAt: onboarding[i] == CleanerOnboardingStatus.pending
            ? null
            : now.subtract(Duration(days: 15 - i)),
        reviewedBy: onboarding[i] == CleanerOnboardingStatus.pending
            ? null
            : targetAdmin.id,
        rejectionReason: onboarding[i] == CleanerOnboardingStatus.rejected
            ? 'Incomplete identity documents for portfolio review.'
            : null,
        createdAt: now.subtract(Duration(days: 35 - i)),
        updatedAt: now.subtract(Duration(days: 8 - i)),
      ),
  ];

  final approvedCleaners = cleanerProfiles
      .where((p) => p.onboardingStatus == CleanerOnboardingStatus.approved)
      .toList();
  final hourlyRates = <int>[45000, 50000, 55000, 60000, 65000];
  final offerings = <PlannedOffering>[
    for (var i = 0; i < approvedCleaners.length; i++)
      PlannedOffering(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.cleanerServices, i + 1),
        cleanerUserId: approvedCleaners[i].userId,
        serviceId: serviceId,
        hourlyRateMinor: hourlyRates[i],
        currencyCode: 'BDT',
        isActive: true,
        createdAt: now.subtract(Duration(days: 30 - i)),
        updatedAt: now.subtract(Duration(days: 5 - i)),
      ),
  ];

  final rateByCleaner = <ObjectId, int>{
    for (final offering in offerings)
      offering.cleanerUserId: offering.hourlyRateMinor,
  };

  var slotIndex = 0;
  PlannedAvailabilitySlot nextSlot({
    required ObjectId cleanerUserId,
    required DateTime startAt,
    required int durationMinutes,
  }) {
    slotIndex += 1;
    final endAt = startAt.add(Duration(minutes: durationMinutes));
    return PlannedAvailabilitySlot(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.availability, slotIndex),
      cleanerUserId: cleanerUserId,
      serviceId: serviceId,
      startAt: startAt,
      endAt: endAt,
      createdAt: startAt.subtract(const Duration(days: 2)),
      updatedAt: startAt.subtract(const Duration(days: 1)),
    );
  }

  final availabilitySlots = <PlannedAvailabilitySlot>[];
  // Open future slots: 4 per approved cleaner across the next 14 days.
  for (var c = 0; c < approvedCleaners.length; c++) {
    final cleanerId = approvedCleaners[c].userId;
    for (var s = 0; s < 4; s++) {
      final dayOffset = 1 + c + (s * 3);
      final start = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset, hours: 9 + s));
      availabilitySlots.add(
        nextSlot(
          cleanerUserId: cleanerId,
          startAt: start,
          durationMinutes: 120,
        ),
      );
    }
  }

  PlannedAddress addressForCustomer(ObjectId customerUserId) {
    return addresses.firstWhere((a) => a.userId == customerUserId);
  }

  // Booking specs: status, customer index, cleaner index (0-4 approved),
  // day offset (negative = past), hour, duration, notes.
  final bookingSpecs = <_BookingSpec>[
    _BookingSpec(
      BookingStatus.pending,
      1,
      0,
      2,
      10,
      120,
      'Please bring supplies',
    ),
    _BookingSpec(BookingStatus.pending, 2, 1, 3, 11, 90, null),
    _BookingSpec(BookingStatus.confirmed, 3, 2, 4, 9, 150, 'Pet-friendly home'),
    _BookingSpec(BookingStatus.confirmed, 4, 3, 5, 14, 120, null),
    _BookingSpec(
      BookingStatus.inProgress,
      5,
      4,
      0,
      now.hour == 0 ? 0 : now.hour - 1,
      180,
      'In progress demo',
    ),
    _BookingSpec(BookingStatus.completed, 1, 0, -5, 10, 120, null),
    _BookingSpec(BookingStatus.completed, 2, 1, -8, 11, 90, null),
    _BookingSpec(BookingStatus.completed, 3, 2, -12, 9, 150, null),
    _BookingSpec(BookingStatus.completed, 4, 3, -18, 13, 120, null),
    _BookingSpec(BookingStatus.completed, 5, 4, -22, 10, 180, null),
    _BookingSpec(BookingStatus.declined, 1, 1, -3, 15, 90, 'Schedule conflict'),
    _BookingSpec(BookingStatus.declined, 2, 2, -7, 16, 120, null),
    _BookingSpec(
      BookingStatus.cancelled,
      3,
      3,
      -10,
      12,
      90,
      'Customer cancelled',
    ),
    _BookingSpec(BookingStatus.cancelled, 4, 0, -14, 11, 120, null),
  ];

  final bookings = <PlannedBooking>[];
  for (var i = 0; i < bookingSpecs.length; i++) {
    final spec = bookingSpecs[i];
    final customer = customers[spec.customerIndex - 1];
    final cleaner = approvedCleaners[spec.cleanerIndex];
    final start = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: spec.dayOffset, hours: spec.hour));
    final slot = nextSlot(
      cleanerUserId: cleaner.userId,
      startAt: start,
      durationMinutes: spec.durationMinutes,
    );
    availabilitySlots.add(slot);
    final hourly = rateByCleaner[cleaner.userId]!;
    final quoted = BookingQuotation.quotedTotalMinor(
      hourlyRateMinor: hourly,
      durationMinutes: spec.durationMinutes,
    );
    final created = start.subtract(const Duration(days: 1));
    final status = spec.status;
    bookings.add(
      PlannedBooking(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.bookings, i + 1),
        customerUserId: customer.id,
        cleanerUserId: cleaner.userId,
        availabilitySlotId: slot.id,
        serviceId: serviceId,
        status: status,
        reservationActive: status.reservationActive,
        durationMinutes: spec.durationMinutes,
        hourlyRateMinor: hourly,
        quotedTotalMinor: quoted,
        currencyCode: 'BDT',
        address: addressForCustomer(customer.id),
        customerNotes: spec.notes,
        idempotencyKey: 'seed-booking-${i + 1}',
        requestFingerprintSeed: 'seed-booking-fp-${i + 1}',
        startAt: slot.startAt,
        endAt: slot.endAt,
        acceptedAt:
            status == BookingStatus.pending || status == BookingStatus.declined
            ? null
            : created.add(const Duration(hours: 2)),
        declinedAt: status == BookingStatus.declined
            ? created.add(const Duration(hours: 3))
            : null,
        startedAt:
            status == BookingStatus.inProgress ||
                status == BookingStatus.completed
            ? slot.startAt.add(const Duration(minutes: 5))
            : null,
        completedAt: status == BookingStatus.completed
            ? slot.endAt.add(const Duration(minutes: 5))
            : null,
        cancelledAt: status == BookingStatus.cancelled
            ? created.add(const Duration(hours: 4))
            : null,
        createdAt: created,
        updatedAt: created.add(const Duration(hours: 5)),
      ),
    );
  }

  final payments = <PlannedPayment>[];
  final paymentStatuses = <PaymentStatus>[
    PaymentStatus.pending, // booking 1 pending
    PaymentStatus.authorized, // booking 2 pending
    PaymentStatus.authorized, // booking 3 confirmed
    PaymentStatus.paid, // booking 4 confirmed
    PaymentStatus.paid, // booking 5 in_progress
    PaymentStatus.paid, // completed 6
    PaymentStatus.paid, // completed 7
    PaymentStatus.paid, // completed 8
    PaymentStatus.paid, // completed 9
    PaymentStatus.partiallyRefunded, // completed 10
    PaymentStatus.failed, // declined 11
    PaymentStatus.cancelled, // declined 12
    PaymentStatus.cancelled, // cancelled 13
    PaymentStatus.refunded, // cancelled 14 (settlement then full refund)
  ];
  for (var i = 0; i < bookings.length; i++) {
    final booking = bookings[i];
    final status = paymentStatuses[i];
    final created = booking.createdAt.add(const Duration(minutes: 30));
    payments.add(
      PlannedPayment(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.payments, i + 1),
        bookingId: booking.id,
        customerUserId: booking.customerUserId,
        cleanerUserId: booking.cleanerUserId,
        status: status,
        amountMinor: booking.quotedTotalMinor,
        currencyCode: booking.currencyCode,
        attemptNumber: 1,
        clientIdempotencyKey: 'seed-pay-${i + 1}',
        requestFingerprintSeed: 'seed-pay-fp-${i + 1}',
        paymentActive: status.paymentActive,
        settlementRecorded: status.settlementRecorded,
        providerPaymentId: 'sandbox_pay_${i + 1}',
        providerReference: 'sandbox_ref_${i + 1}',
        failureCode: status == PaymentStatus.failed ? 'card_declined' : null,
        failureMessage: status == PaymentStatus.failed
            ? 'Provider declined charge'
            : null,
        authorizedAt:
            status == PaymentStatus.authorized || status.settlementRecorded
            ? created.add(const Duration(minutes: 5))
            : null,
        paidAt: status.settlementRecorded
            ? created.add(const Duration(minutes: 10))
            : null,
        failedAt: status == PaymentStatus.failed
            ? created.add(const Duration(minutes: 8))
            : null,
        cancelledAt: status == PaymentStatus.cancelled
            ? created.add(const Duration(minutes: 8))
            : null,
        refundedAt:
            status == PaymentStatus.partiallyRefunded ||
                status == PaymentStatus.refunded
            ? created.add(const Duration(hours: 2))
            : null,
        refundedAmountMinor: status == PaymentStatus.partiallyRefunded
            ? booking.quotedTotalMinor ~/ 2
            : status == PaymentStatus.refunded
            ? booking.quotedTotalMinor
            : 0,
        createdAt: created,
        updatedAt: created.add(const Duration(hours: 1)),
      ),
    );
  }

  final earnings = <PlannedEarning>[];
  var earningIndex = 0;
  for (var i = 0; i < bookings.length; i++) {
    final booking = bookings[i];
    final payment = payments[i];
    if (booking.status != BookingStatus.completed ||
        !payment.status.settlementRecorded) {
      continue;
    }
    earningIndex += 1;
    final gross = payment.status == PaymentStatus.partiallyRefunded
        ? payment.amountMinor - payment.refundedAmountMinor
        : payment.amountMinor;
    final fee = CommissionMath.platformFeeMinor(
      grossMinor: gross,
      commissionBps: commissionBps,
    );
    final net = CommissionMath.cleanerNetMinor(
      grossMinor: gross,
      commissionBps: commissionBps,
    );
    earnings.add(
      PlannedEarning(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.earnings, earningIndex),
        cleanerUserId: booking.cleanerUserId,
        bookingId: booking.id,
        paymentId: payment.id,
        grossAmountMinor: gross,
        commissionBps: commissionBps,
        platformFeeMinor: fee,
        cleanerAmountMinor: net,
        currencyCode: booking.currencyCode,
        sourceEventKey: 'earning:booking:${booking.id.oid}',
        createdAt: payment.paidAt ?? payment.updatedAt,
      ),
    );
  }

  final conversations = <PlannedConversation>[];
  final conversationMembers = <PlannedConversationMember>[];
  final messages = <PlannedMessage>[];
  // Conversations for first 8 bookings.
  var memberIndex = 0;
  var messageIndex = 0;
  for (var i = 0; i < 8; i++) {
    final booking = bookings[i];
    final conversationId = DemoSeedConstants.id(
      DemoSeedIdPrefix.conversations,
      i + 1,
    );
    final created = booking.createdAt.add(const Duration(minutes: 40));
    final bodies = <String>[
      'Hi, confirming the appointment details.',
      'Thanks, I will arrive on time.',
      'Please focus on the kitchen first.',
      'Understood, see you then.',
    ];
    DateTime? lastMessageAt;
    for (var m = 0; m < bodies.length; m++) {
      messageIndex += 1;
      final sentAt = created.add(Duration(minutes: 5 * (m + 1)));
      lastMessageAt = sentAt;
      final fromCustomer = m.isEven;
      messages.add(
        PlannedMessage(
          id: DemoSeedConstants.id(DemoSeedIdPrefix.messages, messageIndex),
          conversationId: conversationId,
          senderUserId: fromCustomer
              ? booking.customerUserId
              : booking.cleanerUserId,
          senderRole: fromCustomer ? UserRole.customer : UserRole.cleaner,
          body: bodies[m],
          clientIdempotencyKey: 'seed-msg-${i + 1}-$m',
          createdAt: sentAt,
        ),
      );
    }
    conversations.add(
      PlannedConversation(
        id: conversationId,
        bookingId: booking.id,
        customerUserId: booking.customerUserId,
        cleanerUserId: booking.cleanerUserId,
        createdAt: created,
        updatedAt: lastMessageAt ?? created,
        lastMessageAt: lastMessageAt,
      ),
    );
    memberIndex += 1;
    conversationMembers.add(
      PlannedConversationMember(
        id: DemoSeedConstants.id(
          DemoSeedIdPrefix.conversationMembers,
          memberIndex,
        ),
        conversationId: conversationId,
        userId: booking.customerUserId,
        role: UserRole.customer,
        createdAt: created,
        updatedAt: created,
      ),
    );
    memberIndex += 1;
    conversationMembers.add(
      PlannedConversationMember(
        id: DemoSeedConstants.id(
          DemoSeedIdPrefix.conversationMembers,
          memberIndex,
        ),
        conversationId: conversationId,
        userId: booking.cleanerUserId,
        role: UserRole.cleaner,
        createdAt: created,
        updatedAt: created,
      ),
    );
  }

  final notifications = <PlannedNotification>[];
  var notifIndex = 0;
  void addNotification({
    required ObjectId userId,
    required String type,
    required String title,
    required String body,
    required String dedupeKey,
    ObjectId? resourceId,
    String? resourceType,
    DateTime? readAt,
    required DateTime createdAt,
  }) {
    if (notifications.length >= 35) {
      return;
    }
    notifIndex += 1;
    notifications.add(
      PlannedNotification(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.notifications, notifIndex),
        userId: userId,
        type: type,
        title: title,
        body: body,
        dedupeKey: dedupeKey,
        resourceType: resourceType,
        resourceId: resourceId,
        readAt: readAt,
        createdAt: createdAt,
      ),
    );
  }

  for (var i = 0; i < bookings.length; i++) {
    final booking = bookings[i];
    addNotification(
      userId: booking.cleanerUserId,
      type: 'booking_requested',
      title: 'New booking request',
      body: 'A customer requested a home cleaning booking.',
      dedupeKey: 'booking_requested:${booking.id.oid}',
      resourceType: 'booking',
      resourceId: booking.id,
      createdAt: booking.createdAt,
    );
    if (booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.inProgress ||
        booking.status == BookingStatus.completed) {
      addNotification(
        userId: booking.customerUserId,
        type: 'booking_confirmed',
        title: 'Booking confirmed',
        body: 'Your cleaner accepted the booking.',
        dedupeKey: 'booking_confirmed:${booking.id.oid}',
        resourceType: 'booking',
        resourceId: booking.id,
        readAt: booking.createdAt.add(const Duration(hours: 1)),
        createdAt: booking.acceptedAt ?? booking.createdAt,
      );
    }
    if (booking.status == BookingStatus.declined) {
      addNotification(
        userId: booking.customerUserId,
        type: 'booking_declined',
        title: 'Booking declined',
        body: 'The cleaner declined this booking request.',
        dedupeKey: 'booking_declined:${booking.id.oid}',
        resourceType: 'booking',
        resourceId: booking.id,
        createdAt: booking.declinedAt ?? booking.updatedAt,
      );
    }
    if (booking.status == BookingStatus.cancelled) {
      addNotification(
        userId: booking.cleanerUserId,
        type: 'booking_cancelled',
        title: 'Booking cancelled',
        body: 'A booking was cancelled.',
        dedupeKey: 'booking_cancelled:${booking.id.oid}',
        resourceType: 'booking',
        resourceId: booking.id,
        createdAt: booking.cancelledAt ?? booking.updatedAt,
      );
    }
  }
  for (var i = 0; i < payments.length && notifications.length < 30; i++) {
    final payment = payments[i];
    if (payment.status == PaymentStatus.paid ||
        payment.status.settlementRecorded) {
      addNotification(
        userId: payment.customerUserId,
        type: 'payment_paid',
        title: 'Payment successful',
        body: 'Your payment was recorded successfully.',
        dedupeKey: 'payment_paid:${payment.id.oid}',
        resourceType: 'payment',
        resourceId: payment.id,
        createdAt: payment.paidAt ?? payment.updatedAt,
      );
    }
    if (payment.status == PaymentStatus.failed) {
      addNotification(
        userId: payment.customerUserId,
        type: 'payment_failed',
        title: 'Payment failed',
        body: 'A payment attempt did not complete.',
        dedupeKey: 'payment_failed:${payment.id.oid}',
        resourceType: 'payment',
        resourceId: payment.id,
        createdAt: payment.failedAt ?? payment.updatedAt,
      );
    }
  }
  for (var i = 0; i < messages.length && notifications.length < 32; i += 4) {
    final message = messages[i];
    final conversation = conversations.firstWhere(
      (c) => c.id == message.conversationId,
    );
    addNotification(
      userId: conversation.cleanerUserId,
      type: 'message_received',
      title: 'New message',
      body: 'You received a booking chat message.',
      dedupeKey: 'message_received:${message.id.oid}',
      resourceType: 'conversation',
      resourceId: conversation.id,
      createdAt: message.createdAt,
    );
  }
  // Trim to 25-35 if somehow over; pad if under 25.
  while (notifications.length > 35) {
    notifications.removeLast();
  }
  var pad = 0;
  while (notifications.length < 25) {
    pad += 1;
    final booking = bookings[pad % bookings.length];
    addNotification(
      userId: booking.customerUserId,
      type: 'job_completed',
      title: 'Job update',
      body: 'A booking status update is available.',
      dedupeKey: 'job_completed_pad:$pad:${booking.id.oid}',
      resourceType: 'booking',
      resourceId: booking.id,
      createdAt: now.subtract(Duration(hours: pad)),
    );
  }

  final completedBookings = bookings
      .where((b) => b.status == BookingStatus.completed)
      .toList();
  final reviews = <PlannedReview>[
    for (var i = 0; i < 5; i++)
      PlannedReview(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.reviews, i + 1),
        bookingId: completedBookings[i].id,
        customerUserId: completedBookings[i].customerUserId,
        cleanerUserId: completedBookings[i].cleanerUserId,
        rating: 5 - (i % 2),
        comment: i == 4
            ? 'Comment held for moderation review.'
            : 'Great cleaning service, would book again.',
        moderationStatus: i == 4
            ? ReviewModerationStatus.hidden
            : ReviewModerationStatus.published,
        hiddenReason: i == 4 ? 'Contains off-topic content.' : null,
        hiddenBy: i == 4 ? targetAdmin.id : null,
        hiddenAt: i == 4
            ? completedBookings[i].completedAt!.add(const Duration(days: 1))
            : null,
        createdAt: completedBookings[i].completedAt!.add(
          const Duration(hours: 6),
        ),
        updatedAt: completedBookings[i].completedAt!.add(
          const Duration(hours: 8),
        ),
      ),
  ];

  final disputes = <PlannedDispute>[
    PlannedDispute(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.disputes, 1),
      bookingId: completedBookings[0].id,
      customerUserId: completedBookings[0].customerUserId,
      cleanerUserId: completedBookings[0].cleanerUserId,
      openedByUserId: completedBookings[0].customerUserId,
      openedByRole: UserRole.customer,
      category: DisputeCategory.serviceQuality,
      status: DisputeStatus.open,
      subject: 'Missed bathroom corners',
      description:
          'Bathroom corners were not cleaned thoroughly during the visit.',
      createdAt: completedBookings[0].completedAt!.add(const Duration(days: 1)),
      updatedAt: completedBookings[0].completedAt!.add(const Duration(days: 1)),
    ),
    PlannedDispute(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.disputes, 2),
      bookingId: completedBookings[1].id,
      customerUserId: completedBookings[1].customerUserId,
      cleanerUserId: completedBookings[1].cleanerUserId,
      openedByUserId: completedBookings[1].customerUserId,
      openedByRole: UserRole.customer,
      category: DisputeCategory.bookingIssue,
      status: DisputeStatus.underReview,
      subject: 'Late arrival',
      description:
          'Cleaner arrived significantly later than the booked window.',
      createdAt: completedBookings[1].completedAt!.add(const Duration(days: 1)),
      updatedAt: completedBookings[1].completedAt!.add(const Duration(days: 2)),
    ),
    PlannedDispute(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.disputes, 3),
      bookingId: completedBookings[2].id,
      customerUserId: completedBookings[2].customerUserId,
      cleanerUserId: completedBookings[2].cleanerUserId,
      openedByUserId: completedBookings[2].cleanerUserId,
      openedByRole: UserRole.cleaner,
      category: DisputeCategory.customerNoShow,
      status: DisputeStatus.resolved,
      subject: 'Access delay resolved',
      description: 'Customer access delay was clarified after follow-up.',
      resolution: 'No further action required after mutual clarification.',
      resolvedBy: targetAdmin.id,
      resolvedAt: completedBookings[2].completedAt!.add(
        const Duration(days: 3),
      ),
      createdAt: completedBookings[2].completedAt!.add(const Duration(days: 1)),
      updatedAt: completedBookings[2].completedAt!.add(const Duration(days: 3)),
    ),
  ];

  final auditLogs = <PlannedAuditLog>[
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 1),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'cleaner_approved',
      targetType: 'cleaner_profile',
      targetId: cleanerProfiles[0].id,
      createdAt: now.subtract(const Duration(days: 15)),
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 2),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'cleaner_approved',
      targetType: 'cleaner_profile',
      targetId: cleanerProfiles[1].id,
      createdAt: now.subtract(const Duration(days: 14)),
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 3),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'cleaner_rejected',
      targetType: 'cleaner_profile',
      targetId: cleanerProfiles[6].id,
      reason: 'Incomplete identity documents.',
      createdAt: now.subtract(const Duration(days: 12)),
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 4),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'user_suspended',
      targetType: 'user',
      targetId: customers[5].id,
      reason: 'Policy review hold.',
      createdAt: now.subtract(const Duration(days: 9)),
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 5),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'review_hidden',
      targetType: 'review',
      targetId: reviews[4].id,
      reason: 'Off-topic content.',
      createdAt: reviews[4].hiddenAt!,
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 6),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'dispute_review_started',
      targetType: 'dispute',
      targetId: disputes[1].id,
      createdAt: disputes[1].updatedAt,
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 7),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'dispute_resolved',
      targetType: 'dispute',
      targetId: disputes[2].id,
      createdAt: disputes[2].resolvedAt!,
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 8),
      actorUserId: demoAdmin.id,
      actorRole: UserRole.admin,
      action: 'payment_refund_requested',
      targetType: 'payment',
      targetId: payments[9].id,
      createdAt: payments[9].refundedAt!,
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 9),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'payout_processing_started',
      targetType: 'payout',
      targetId: DemoSeedConstants.id(DemoSeedIdPrefix.payouts, 2),
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    PlannedAuditLog(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.auditLogs, 10),
      actorUserId: targetAdmin.id,
      actorRole: UserRole.admin,
      action: 'cleaner_approved',
      targetType: 'cleaner_profile',
      targetId: cleanerProfiles[2].id,
      createdAt: now.subtract(const Duration(days: 13)),
    ),
  ];

  final payoutStatuses = <PayoutStatus>[
    PayoutStatus.requested,
    PayoutStatus.processing,
    PayoutStatus.paid,
    PayoutStatus.failed,
  ];
  final payouts = <PlannedPayout>[
    for (var i = 0; i < 4; i++)
      PlannedPayout(
        id: DemoSeedConstants.id(DemoSeedIdPrefix.payouts, i + 1),
        cleanerUserId: approvedCleaners[i].userId,
        amountMinor: 20000 + (i * 5000),
        currencyCode: 'BDT',
        status: payoutStatuses[i],
        attemptNumber: 1,
        clientIdempotencyKey: 'seed-payout-${i + 1}',
        requestFingerprintSeed: 'seed-payout-fp-${i + 1}',
        payoutActive: payoutStatuses[i].payoutActive,
        provider: 'sandbox',
        providerPayoutId: 'sandbox_payout_${i + 1}',
        requestedAt: now.subtract(Duration(days: 6 - i)),
        processingAt:
            payoutStatuses[i] == PayoutStatus.processing ||
                payoutStatuses[i] == PayoutStatus.paid ||
                payoutStatuses[i] == PayoutStatus.failed
            ? now.subtract(Duration(days: 5 - i))
            : null,
        paidAt: payoutStatuses[i] == PayoutStatus.paid
            ? now.subtract(Duration(days: 4 - i))
            : null,
        failedAt: payoutStatuses[i] == PayoutStatus.failed
            ? now.subtract(Duration(days: 3 - i))
            : null,
        failureCode: payoutStatuses[i] == PayoutStatus.failed
            ? 'provider_error'
            : null,
        failureMessage: payoutStatuses[i] == PayoutStatus.failed
            ? 'Sandbox provider reported failure'
            : null,
        processedBy:
            payoutStatuses[i] == PayoutStatus.processing ||
                payoutStatuses[i] == PayoutStatus.paid ||
                payoutStatuses[i] == PayoutStatus.failed
            ? targetAdmin.id
            : null,
        createdAt: now.subtract(Duration(days: 6 - i)),
        updatedAt: now.subtract(Duration(days: 3 - i)),
      ),
  ];

  final paymentWebhooks = <PlannedPaymentWebhook>[
    PlannedPaymentWebhook(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.paymentWebhooks, 1),
      providerEventId: 'sandbox_evt_pay_1',
      eventType: 'payment.paid',
      providerPaymentId: payments[5].providerPaymentId!,
      payloadSha256Seed: 'seed-pay-webhook-1',
      processingStatus: 'processed',
      processedAt: payments[5].paidAt,
      createdAt: payments[5].paidAt ?? payments[5].updatedAt,
    ),
    PlannedPaymentWebhook(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.paymentWebhooks, 2),
      providerEventId: 'sandbox_evt_pay_2',
      eventType: 'payment.failed',
      providerPaymentId: payments[10].providerPaymentId!,
      payloadSha256Seed: 'seed-pay-webhook-2',
      processingStatus: 'processed',
      processedAt: payments[10].failedAt,
      createdAt: payments[10].failedAt ?? payments[10].updatedAt,
    ),
  ];

  final payoutWebhooks = <PlannedPayoutWebhook>[
    PlannedPayoutWebhook(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.payoutWebhooks, 1),
      providerEventId: 'sandbox_evt_payout_1',
      eventType: 'payout.paid',
      providerPayoutId: payouts[2].providerPayoutId!,
      payloadSha256Seed: 'seed-payout-webhook-1',
      processingStatus: 'processed',
      processedAt: payouts[2].paidAt,
      createdAt: payouts[2].paidAt ?? payouts[2].updatedAt,
    ),
    PlannedPayoutWebhook(
      id: DemoSeedConstants.id(DemoSeedIdPrefix.payoutWebhooks, 2),
      providerEventId: 'sandbox_evt_payout_2',
      eventType: 'payout.failed',
      providerPayoutId: payouts[3].providerPayoutId!,
      payloadSha256Seed: 'seed-payout-webhook-2',
      processingStatus: 'processed',
      processedAt: payouts[3].failedAt,
      createdAt: payouts[3].failedAt ?? payouts[3].updatedAt,
    ),
  ];

  final plan = DemoSeedPlan(
    nowUtc: now,
    serviceId: serviceId,
    commissionBps: commissionBps,
    users: users,
    customerProfiles: customerProfiles,
    cleanerProfiles: cleanerProfiles,
    addresses: addresses,
    offerings: offerings,
    availabilitySlots: availabilitySlots,
    bookings: bookings,
    payments: payments,
    earnings: earnings,
    conversations: conversations,
    conversationMembers: conversationMembers,
    messages: messages,
    notifications: notifications,
    reviews: reviews,
    disputes: disputes,
    auditLogs: auditLogs,
    payouts: payouts,
    paymentWebhooks: paymentWebhooks,
    payoutWebhooks: payoutWebhooks,
  );
  plan.validate();
  return plan;
}

ObjectId _uid(int n) => DemoSeedConstants.id(DemoSeedIdPrefix.users, n);

PlannedUser _customer(
  int index,
  String fullName,
  String email,
  AccountStatus status,
) {
  return PlannedUser(
    id: _uid(index),
    email: email,
    emailNormalized: email,
    fullName: fullName,
    role: UserRole.customer,
    accountStatus: status,
    emailVerified: true,
    phoneE164: '+880170000000$index',
    isTargetAdmin: false,
  );
}

PlannedUser _cleaner(int index, String fullName, String email) {
  return PlannedUser(
    id: _uid(index),
    email: email,
    emailNormalized: email,
    fullName: fullName,
    role: UserRole.cleaner,
    accountStatus: AccountStatus.active,
    emailVerified: true,
    phoneE164: '+88017000000${index.toString().padLeft(2, '0')}',
    isTargetAdmin: false,
  );
}

class _BookingSpec {
  const _BookingSpec(
    this.status,
    this.customerIndex,
    this.cleanerIndex,
    this.dayOffset,
    this.hour,
    this.durationMinutes,
    this.notes,
  );

  final BookingStatus status;
  final int customerIndex;
  final int cleanerIndex;
  final int dayOffset;
  final int hour;
  final int durationMinutes;
  final String? notes;
}
