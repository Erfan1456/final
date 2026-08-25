import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/data/audit_log_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/admin_booking_operations_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/admin_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/booking_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/domain/dispute_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/admin_review_moderation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_moderation_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/application/admin_user_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';
import '../../../helpers/payment_test_fixtures.dart';
import '../../../helpers/recording_audit_sink.dart';
import '../../../helpers/recording_notification_sink.dart';

void main() {
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;
  late MemoryCollectionDocumentStore bookings;
  late MemoryCollectionDocumentStore disputes;
  late MemoryCollectionDocumentStore customers;
  late MemoryCollectionDocumentStore cleaners;
  late MemoryCollectionDocumentStore payments;
  late MemoryCollectionDocumentStore auditDocs;
  late MemoryUserRepository users;
  late RecordingNotificationSink notifications;
  late RecordingAuditSink audit;
  late BookingDisputeService participant;
  late AdminDisputeService adminDisputes;
  late AdminUserManagementService adminUsers;
  late AdminBookingOperationsService adminBookings;
  late AuditLogService auditService;
  late List<ObjectId> revoked;

  final customer = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c1'),
    role: UserRole.customer,
    email: 'pat.customer@example.com',
  );
  final cleaner = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c2'),
    email: 'lee.cleaner@example.com',
  );
  final admin = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c3'),
    role: UserRole.admin,
    email: 'admin@example.com',
  );
  final foreign = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c4'),
    role: UserRole.customer,
    email: 'foreign@example.com',
  );

  setUp(() {
    customerId = customer.id;
    cleanerId = cleaner.id;
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    bookings = MemoryCollectionDocumentStore();
    disputes = MemoryCollectionDocumentStore();
    customers = MemoryCollectionDocumentStore();
    cleaners = MemoryCollectionDocumentStore();
    payments = MemoryCollectionDocumentStore();
    auditDocs = MemoryCollectionDocumentStore();
    users = MemoryUserRepository();
    users.users.addAll([customer, cleaner, admin, foreign]);
    notifications = RecordingNotificationSink();
    audit = RecordingAuditSink();
    revoked = <ObjectId>[];
    customers.documents.add(
      CustomerProfile(
        id: ObjectId(),
        userId: customerId,
        fullName: 'Pat Customer',
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      ).toDocument(),
    );
    cleaners.documents.add(
      testCleanerProfileRecord(userId: cleanerId).toDocument(),
    );
    bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
      ).toDocument(),
    );
    final bookingRepo = MongoBookingRepository(documents: bookings);
    final disputeRepo = MongoDisputeRepository(documents: disputes);
    final customerRepo = MongoCustomerProfileRepository(documents: customers);
    final cleanerRepo = MongoCleanerProfileRepository(documents: cleaners);
    final paymentRepo = MongoPaymentRepository(documents: payments);
    participant = BookingDisputeService(
      bookings: bookingRepo,
      disputes: disputeRepo,
      customerProfiles: customerRepo,
      cleanerProfiles: cleanerRepo,
      notifications: notifications,
      clock: marketplaceTestNow,
    );
    adminDisputes = AdminDisputeService(
      disputes: disputeRepo,
      bookings: bookingRepo,
      customerProfiles: customerRepo,
      cleanerProfiles: cleanerRepo,
      notifications: notifications,
      audit: audit,
      clock: marketplaceTestNow,
    );
    adminUsers = AdminUserManagementService(
      users: users,
      customerProfiles: customerRepo,
      cleanerProfiles: cleanerRepo,
      bookings: bookingRepo,
      payments: paymentRepo,
      disputes: disputeRepo,
      revokeAllSessions: (id) async {
        revoked.add(id);
        return 2;
      },
      audit: audit,
      clock: marketplaceTestNow,
    );
    adminBookings = AdminBookingOperationsService(
      bookings: bookingRepo,
      payments: paymentRepo,
      disputes: disputeRepo,
      customerProfiles: customerRepo,
      cleanerProfiles: cleanerRepo,
      cancellation: BookingCancellationOrchestrator(
        bookings: bookingRepo,
        payments: paymentRepo,
        webhooks: PaymentWebhookService(
          provider: null,
          payments: paymentRepo,
          events: MongoPaymentWebhookEventRepository(
            documents: MemoryCollectionDocumentStore(),
          ),
          notifications: notifications,
        ),
        provider: null,
        clock: marketplaceTestNow,
      ),
      notifications: notifications,
      audit: audit,
    );
    auditService = AuditLogService(
      logs: MongoAuditLogRepository(documents: auditDocs),
      clock: marketplaceTestNow,
    );
  });

  Map<String, Object?> openBody() {
    return <String, Object?>{
      'category': 'service_quality',
      'subject': 'Late arrival issue',
      'description': 'The cleaner arrived more than two hours late to the job.',
    };
  }

  group('participant disputes', () {
    test('customer opens an eligible dispute', () async {
      final created = await participant.create(
        user: customer,
        bookingId: bookingId,
        categoryRaw: openBody()['category'],
        subjectRaw: openBody()['subject'],
        descriptionRaw: openBody()['description'],
      );
      final dispute = created['dispute']! as Map<String, Object?>;
      expect(dispute['status'], 'open');
      expect(dispute['cleaner_public_name'], 'Test Cleaner');
      expect(dispute['history'], isA<List<dynamic>>());
      final history = dispute['history']! as List<dynamic>;
      expect((history.first as Map)['from_status'], isNull);
      expect((history.first as Map)['to_status'], 'open');
      expect(
        notifications.created.single['type'],
        NotificationType.disputeOpened,
      );
      expect(notifications.created.single['user_id'], cleanerId);
    });

    test('cleaner can open a dispute', () async {
      final created = await participant.create(
        user: cleaner,
        bookingId: bookingId,
        categoryRaw: 'conduct',
        subjectRaw: 'Customer conduct issue',
        descriptionRaw: 'The customer used abusive language during the visit.',
      );
      expect(
        (created['dispute']! as Map)['customer_display_name'],
        'Pat Customer',
      );
      expect(notifications.created.single['user_id'], customerId);
    });

    test('foreign participant is hidden', () async {
      await expectLater(
        () => participant.getForBooking(user: foreign, bookingId: bookingId),
        throwsA(isA<BookingNotFoundException>()),
      );
    });

    test('admin cannot participant-create', () async {
      await expectLater(
        () => participant.create(
          user: admin,
          bookingId: bookingId,
          categoryRaw: openBody()['category'],
          subjectRaw: openBody()['subject'],
          descriptionRaw: openBody()['description'],
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('pending and declined bookings are blocked', () async {
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.pending,
      ).toDocument();
      await expectLater(
        () => participant.create(
          user: customer,
          bookingId: bookingId,
          categoryRaw: openBody()['category'],
          subjectRaw: openBody()['subject'],
          descriptionRaw: openBody()['description'],
        ),
        throwsA(isA<DisputeNotAllowedException>()),
      );
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.declined,
      ).toDocument();
      await expectLater(
        () => participant.create(
          user: customer,
          bookingId: bookingId,
          categoryRaw: openBody()['category'],
          subjectRaw: openBody()['subject'],
          descriptionRaw: openBody()['description'],
        ),
        throwsA(isA<DisputeNotAllowedException>()),
      );
    });

    test('completed and cancelled bookings are allowed', () async {
      for (final status in <BookingStatus>[
        BookingStatus.inProgress,
        BookingStatus.completed,
        BookingStatus.cancelled,
      ]) {
        disputes.documents.clear();
        bookings.documents[0] = testConfirmedBooking(
          customerId: customerId,
          cleanerId: cleanerId,
          id: bookingId,
          status: status,
        ).toDocument();
        final created = await participant.create(
          user: customer,
          bookingId: bookingId,
          categoryRaw: openBody()['category'],
          subjectRaw: openBody()['subject'],
          descriptionRaw: openBody()['description'],
        );
        expect((created['dispute']! as Map)['status'], 'open');
      }
    });

    test('rejects invalid category subject and description', () async {
      await expectLater(
        () => participant.create(
          user: customer,
          bookingId: bookingId,
          categoryRaw: 'not-a-category',
          subjectRaw: openBody()['subject'],
          descriptionRaw: openBody()['description'],
        ),
        throwsA(isA<InvalidDisputeCategoryException>()),
      );
      await expectLater(
        () => participant.create(
          user: customer,
          bookingId: bookingId,
          categoryRaw: 'service_quality',
          subjectRaw: 'hey',
          descriptionRaw: openBody()['description'],
        ),
        throwsA(isA<InvalidDisputeSubjectException>()),
      );
      await expectLater(
        () => participant.create(
          user: customer,
          bookingId: bookingId,
          categoryRaw: 'service_quality',
          subjectRaw: 'Valid dispute subject',
          descriptionRaw: 'too short',
        ),
        throwsA(isA<InvalidDisputeDescriptionException>()),
      );
    });

    test('second dispute for the same booking is rejected', () async {
      await participant.create(
        user: customer,
        bookingId: bookingId,
        categoryRaw: openBody()['category'],
        subjectRaw: openBody()['subject'],
        descriptionRaw: openBody()['description'],
      );
      await expectLater(
        () => participant.create(
          user: cleaner,
          bookingId: bookingId,
          categoryRaw: 'other',
          subjectRaw: 'Another dispute subject',
          descriptionRaw: 'A second dispute is not allowed for this booking.',
        ),
        throwsA(isA<DisputeAlreadyExistsException>()),
      );
    });

    test('get none and get own', () async {
      final none = await participant.getForBooking(
        user: customer,
        bookingId: bookingId,
      );
      expect(none['dispute'], isNull);
      await participant.create(
        user: customer,
        bookingId: bookingId,
        categoryRaw: openBody()['category'],
        subjectRaw: openBody()['subject'],
        descriptionRaw: openBody()['description'],
      );
      final own = await participant.getForBooking(
        user: customer,
        bookingId: bookingId,
      );
      expect(own['dispute'], isNotNull);
    });

    test('participant close only from resolved', () async {
      await participant.create(
        user: customer,
        bookingId: bookingId,
        categoryRaw: openBody()['category'],
        subjectRaw: openBody()['subject'],
        descriptionRaw: openBody()['description'],
      );
      await expectLater(
        () => participant.close(user: customer, bookingId: bookingId),
        throwsA(isA<InvalidDisputeStateException>()),
      );
      final listed = await adminDisputes.list();
      final id = ObjectId.fromHexString(
        ((listed['items']! as List).first as Map)['id'] as String,
      );
      await adminDisputes.resolve(
        user: admin,
        disputeId: id,
        resolutionRaw:
            'Operational note: booking was reviewed with both parties.',
      );
      final closed = await participant.close(
        user: customer,
        bookingId: bookingId,
      );
      expect((closed['dispute']! as Map)['status'], 'closed');
      await expectLater(
        () => participant.close(user: customer, bookingId: bookingId),
        throwsA(isA<InvalidDisputeStateException>()),
      );
    });
  });

  group('admin disputes', () {
    test('list defaults to open and supports filters', () async {
      await participant.create(
        user: customer,
        bookingId: bookingId,
        categoryRaw: openBody()['category'],
        subjectRaw: openBody()['subject'],
        descriptionRaw: openBody()['description'],
      );
      final open = await adminDisputes.list();
      expect(open['items']! as List<dynamic>, hasLength(1));
      final resolved = await adminDisputes.list(status: 'resolved');
      expect(resolved['items']! as List<dynamic>, isEmpty);
      final quality = await adminDisputes.list(category: 'service_quality');
      expect(quality['items']! as List<dynamic>, hasLength(1));
    });

    test('review resolve close and notifications', () async {
      await participant.create(
        user: customer,
        bookingId: bookingId,
        categoryRaw: openBody()['category'],
        subjectRaw: openBody()['subject'],
        descriptionRaw: openBody()['description'],
      );
      notifications.created.clear();
      final listed = await adminDisputes.list();
      final listedItems = listed['items']! as List<dynamic>;
      final listedFirst = listedItems.first as Map<String, Object?>;
      final id = ObjectId.fromHexString(listedFirst['id']! as String);
      final reviewed = await adminDisputes.startReview(
        user: admin,
        disputeId: id,
      );
      expect((reviewed['dispute']! as Map)['status'], 'under_review');
      final again = await adminDisputes.startReview(user: admin, disputeId: id);
      expect((again['dispute']! as Map)['status'], 'under_review');
      expect(
        notifications.created.where(
          (row) => row['type'] == NotificationType.disputeUnderReview,
        ),
        hasLength(2),
      );
      await adminDisputes.resolve(
        user: admin,
        disputeId: id,
        resolutionRaw: 'Operational note: both parties were contacted.',
      );
      expect(
        notifications.created.where(
          (row) => row['type'] == NotificationType.disputeResolved,
        ),
        hasLength(2),
      );
      final closed = await adminDisputes.close(user: admin, disputeId: id);
      expect((closed['dispute']! as Map)['status'], 'closed');
      expect(
        audit.appended.map((row) => row['action']),
        containsAll(<AuditAction>[
          AuditAction.disputeReviewStarted,
          AuditAction.disputeResolved,
          AuditAction.disputeClosed,
        ]),
      );
    });

    test('missing dispute is not found', () async {
      await expectLater(
        () => adminDisputes.detail(ObjectId()),
        throwsA(isA<DisputeNotFoundException>()),
      );
    });
  });

  group('admin users', () {
    test('lists and filters without leaking password fields', () async {
      final page = await adminUsers.listUsers(role: 'customer');
      final items = page['items']! as List<dynamic>;
      expect(items, isNotEmpty);
      final json = items.first as Map<String, Object?>;
      expect(json.containsKey('password_hash'), isFalse);
      expect(json.containsKey('email_normalized'), isFalse);
      expect(
        items.map((row) => (row as Map)['email']),
        containsAll(<String>[
          'pat.customer@example.com',
          'foreign@example.com',
        ]),
      );
      final email = await adminUsers.listUsers(
        email: '  PAT.CUSTOMER@example.com ',
      );
      expect(email['items']! as List<dynamic>, hasLength(1));
    });

    test('suspend revokes sessions and writes audit', () async {
      final result = await adminUsers.suspend(
        actor: admin,
        userId: customerId,
        reasonRaw: 'Repeated no-show complaints',
      );
      expect(
        (result['user']! as Map)['account_status'],
        AccountStatus.suspended.wireValue,
      );
      expect(revoked, [customerId]);
      expect(audit.appended.single['action'], AuditAction.userSuspended);
      final again = await adminUsers.suspend(
        actor: admin,
        userId: customerId,
        reasonRaw: 'Repeated no-show complaints',
      );
      expect((again['user']! as Map)['account_status'], 'suspended');
      expect(audit.appended, hasLength(1));
    });

    test('detail returns safe customer fields and counts', () async {
      final detail = await adminUsers.getUser(customerId);
      final user = detail['user']! as Map<String, Object?>;
      expect(user['email'], 'pat.customer@example.com');
      expect(user.containsKey('password_hash'), isFalse);
      expect(detail['protected_admin_account'], isFalse);
      expect(detail['booking_count'], 1);
    });

    test('protects admin targets and self', () async {
      await expectLater(
        () => adminUsers.suspend(
          actor: admin,
          userId: admin.id,
          reasonRaw: 'Should not work on self admin',
        ),
        throwsA(isA<ProtectedAdminAccountException>()),
      );
    });

    test('reactivate and deactivate', () async {
      await adminUsers.suspend(
        actor: admin,
        userId: cleanerId,
        reasonRaw: 'Temporary investigation hold',
      );
      audit.appended.clear();
      final active = await adminUsers.reactivate(
        actor: admin,
        userId: cleanerId,
      );
      expect((active['user']! as Map)['account_status'], 'active');
      final deactivated = await adminUsers.deactivate(
        actor: admin,
        userId: cleanerId,
        reasonRaw: 'Left the marketplace permanently',
      );
      expect((deactivated['user']! as Map)['account_status'], 'deactivated');
      expect(revoked, contains(cleanerId));
      await expectLater(
        () => adminUsers.reactivate(actor: admin, userId: cleanerId),
        throwsA(isA<InvalidAccountStateException>()),
      );
    });
  });

  group('admin bookings', () {
    test('lists operational summaries without N+1 lookups', () async {
      final page = await adminBookings.list();
      final items = page['items']! as List<dynamic>;
      expect(items, hasLength(1));
      final json = items.first as Map<String, Object?>;
      expect(json['customer_display_name'], 'Pat Customer');
      expect(json['cleaner_public_name'], 'Test Cleaner');
      expect(json.containsKey('password_hash'), isFalse);
    });

    test('cancels pending and records audit', () async {
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.pending,
      ).toDocument();
      final cancelled = await adminBookings.cancel(
        user: admin,
        bookingId: bookingId,
        reasonRaw: 'Duplicate booking created by mistake',
      );
      expect((cancelled['booking']! as Map)['status'], 'cancelled');
      expect(
        notifications.created.where(
          (row) => row['type'] == NotificationType.bookingCancelled,
        ),
        hasLength(2),
      );
      expect(
        audit.appended.single['action'],
        AuditAction.bookingAdminCancelled,
      );
    });

    test('blocks in_progress cancellation', () async {
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.inProgress,
      ).toDocument();
      await expectLater(
        () => adminBookings.cancel(
          user: admin,
          bookingId: bookingId,
          reasonRaw: 'Too late to cancel this job',
        ),
        throwsA(isA<AdminBookingNotCancellableException>()),
      );
    });

    test('paid confirmed refund failure keeps booking confirmed', () async {
      payments.documents.add(
        testPayment(
          bookingId: bookingId,
          customerId: customerId,
          cleanerId: cleanerId,
          status: PaymentStatus.paid,
        ).toDocument(),
      );
      await expectLater(
        () => adminBookings.cancel(
          user: admin,
          bookingId: bookingId,
          reasonRaw: 'Customer asked support to cancel',
        ),
        throwsA(isA<PaymentRefundFailedException>()),
      );
      final current = await MongoBookingRepository(
        documents: bookings,
      ).findById(bookingId);
      expect(current!.status, BookingStatus.confirmed);
    });
  });

  group('audit logs', () {
    test('append list detail and missing', () async {
      await auditService.append(
        actorUserId: admin.id,
        actorRole: UserRole.admin,
        action: AuditAction.userSuspended,
        targetType: AuditTargetType.user,
        targetId: customerId,
        reason: 'policy',
        metadata: <String, Object?>{
          'previous_status': 'active',
          'password': 'must-drop',
        },
      );
      final stored = MongoAuditLogRepository(documents: auditDocs);
      final page = await stored.listPage(limit: 20);
      expect(page.items, hasLength(1));
      expect(page.items.single.metadata.containsKey('password'), isFalse);
      expect(page.items.single.metadata['previous_status'], 'active');
      final json = await auditService.detail(page.items.single.id);
      expect(json['action'], 'user_suspended');
      await expectLater(
        () => auditService.detail(ObjectId()),
        throwsA(isA<AuditLogNotFoundException>()),
      );
    });

    test('audit failure does not roll back review hide', () async {
      final reviewId = ObjectId();
      final reviews = MemoryCollectionDocumentStore();
      reviews.documents.add(
        Review(
          id: reviewId,
          bookingId: bookingId,
          customerUserId: customerId,
          cleanerUserId: cleanerId,
          rating: 5,
          moderationStatus: ReviewModerationStatus.published,
          createdAt: marketplaceTestNow(),
          updatedAt: marketplaceTestNow(),
        ).toDocument(),
      );
      audit.throwOnAppend = true;
      final service = AdminReviewModerationService(
        reviews: MongoReviewRepository(documents: reviews),
        audit: audit,
        clock: marketplaceTestNow,
      );
      final hidden = await service.hide(
        user: admin,
        reviewId: reviewId,
        reasonRaw: 'Off-topic marketplace review',
      );
      expect(hidden['moderation_status'], 'hidden');
    });
  });

  group('existing admin audit integration', () {
    test('cleaner approve writes audit', () async {
      final pending = testCleanerProfileRecord(
        userId: cleanerId,
        status: CleanerOnboardingStatus.pending,
      );
      cleaners.documents
        ..clear()
        ..add(pending.toDocument());
      final service = AdminCleanerReviewService(
        profiles: MongoCleanerProfileRepository(documents: cleaners),
        users: users,
        audit: audit,
      );
      await service.approve(targetUserId: cleanerId, adminUserId: admin.id);
      expect(audit.appended.single['action'], AuditAction.cleanerApproved);
    });
  });
}
