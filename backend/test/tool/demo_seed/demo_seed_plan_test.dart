import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:test/test.dart';

import '../../../tool/demo_seed/demo_seed_constants.dart';
import '../../../tool/demo_seed/demo_seed_documents.dart';
import '../../../tool/demo_seed/demo_seed_integrity.dart';
import '../../../tool/demo_seed/demo_seed_plan.dart';

const _fakeAdminHash =
    r'$argon2id$v=19$m=19456,t=2,p=1$testhashsaltxxxx$'
    'testhashdigestxxxxxxxxxxxxxxxx';
const _fakeSharedHash =
    r'$argon2id$v=19$m=19456,t=2,p=1$sharedhashsaltxxx$'
    'sharedhashdigestxxxxxxxxxxxxxxx';

void main() {
  late DemoSeedPlan plan;

  setUp(() {
    plan = buildDemoSeedPlan(
      nowUtc: DateTime.utc(2026, 8, 27, 12),
      serviceId: DemoSeedConstants.dryRunServiceId,
      commissionBps: ServerConfig.defaultPlatformCommissionBps,
    );
  });

  test('plan has exactly 15 users with 6/7/2 roles', () {
    expect(plan.users, hasLength(15));
    expect(plan.roleCounts[UserRole.customer], 6);
    expect(plan.roleCounts[UserRole.cleaner], 7);
    expect(plan.roleCounts[UserRole.admin], 2);
  });

  test('emails are unique and only target admin is non-example', () {
    final emails = plan.users.map((u) => u.emailNormalized).toSet();
    expect(emails, hasLength(15));
    final nonExample = plan.users.where(
      (u) => !u.emailNormalized.endsWith('@example.com'),
    );
    expect(nonExample, hasLength(1));
    expect(nonExample.single.isTargetAdmin, isTrue);
    expect(
      nonExample.single.emailNormalized,
      DemoSeedConstants.targetAdminEmailNormalized,
    );
  });

  test('offerings are one per approved cleaner', () {
    expect(plan.offerings, hasLength(5));
    final approved = plan.cleanerProfiles
        .where((p) => p.onboardingStatus == CleanerOnboardingStatus.approved)
        .map((p) => p.userId)
        .toSet();
    expect(approved, hasLength(5));
    for (final cleanerId in approved) {
      expect(
        plan.offerings.where((o) => o.cleanerUserId == cleanerId),
        hasLength(1),
      );
    }
  });

  test('booking status distribution and active reservations', () {
    expect(plan.bookings, hasLength(14));
    expect(plan.bookingStatusCounts[BookingStatus.pending], 2);
    expect(plan.bookingStatusCounts[BookingStatus.confirmed], 2);
    expect(plan.bookingStatusCounts[BookingStatus.inProgress], 1);
    expect(plan.bookingStatusCounts[BookingStatus.completed], 5);
    expect(plan.bookingStatusCounts[BookingStatus.declined], 2);
    expect(plan.bookingStatusCounts[BookingStatus.cancelled], 2);

    final activeSlots = <String>{};
    for (final booking in plan.bookings) {
      expect(booking.reservationActive, booking.status.reservationActive);
      if (booking.reservationActive) {
        expect(activeSlots.add(booking.availabilitySlotId.oid), isTrue);
      }
    }
  });

  test('reviews only on completed bookings with moderation mix', () {
    expect(plan.reviews, hasLength(5));
    expect(
      plan.reviews.where(
        (r) => r.moderationStatus == ReviewModerationStatus.published,
      ),
      hasLength(4),
    );
    expect(
      plan.reviews.where(
        (r) => r.moderationStatus == ReviewModerationStatus.hidden,
      ),
      hasLength(1),
    );
    final completed = plan.bookings
        .where((b) => b.status == BookingStatus.completed)
        .map((b) => b.id.oid)
        .toSet();
    for (final review in plan.reviews) {
      expect(completed.contains(review.bookingId.oid), isTrue);
    }
  });

  test('conversations participants match booking parties', () {
    expect(plan.conversations, hasLength(8));
    final bookingsById = {
      for (final booking in plan.bookings) booking.id.oid: booking,
    };
    for (final conversation in plan.conversations) {
      final booking = bookingsById[conversation.bookingId.oid]!;
      expect(conversation.customerUserId, booking.customerUserId);
      expect(conversation.cleanerUserId, booking.cleanerUserId);
    }
  });

  test('notifications stay within 25-35', () {
    expect(plan.notifications.length, inInclusiveRange(25, 35));
  });

  test('documents use fake argon2 hashes and omit secret fields', () {
    final hashes = <String, String>{
      for (final user in plan.users)
        user.emailNormalized: user.isTargetAdmin
            ? _fakeAdminHash
            : _fakeSharedHash,
    };
    final bundle = buildDemoSeedDocuments(
      plan: plan,
      passwordHashByEmailNormalized: hashes,
    );

    expect(bundle.documentsByCollection[CollectionNames.users], hasLength(15));
    expect(bundle.manifest.seedKey, DemoSeedConstants.seedKey);
    expect(bundle.manifest.fingerprint, isNotEmpty);
    expect(
      bundle.manifest.collectionIds.containsKey(CollectionNames.users),
      isTrue,
    );

    DemoSeedIntegrity.assertDocumentsSafe(bundle.documentsByCollection);
    DemoSeedIntegrity.assertFinancialSplits(plan);

    for (final userDoc
        in bundle.documentsByCollection[CollectionNames.users]!) {
      expect(userDoc.containsKey('password'), isFalse);
      expect(
        DemoSeedIntegrity.looksLikeArgon2Hash(userDoc['password_hash']),
        isTrue,
      );
      expect(userDoc.keys, isNot(contains('jwt')));
      expect(userDoc.keys, isNot(contains('access_token')));
      expect(userDoc.keys, isNot(contains('refresh_token')));
    }

    expect(
      bundle.manifest.toDocument(id: DemoSeedConstants.id('e5', 1)).keys,
      isNot(contains('password_hash')),
    );
  });

  test('count summary includes core collections', () {
    final counts = plan.countSummary();
    expect(counts['users'], 15);
    expect(counts['addresses'], 9);
    expect(counts['cleaner_services'], 5);
    expect(counts['bookings'], 14);
    expect(counts['reviews'], 5);
    expect(counts['disputes'], 3);
    expect(counts['payout_requests'], 4);
    expect(counts['earnings_ledger'], greaterThanOrEqualTo(5));
  });
}
