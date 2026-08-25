import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/data/audit_log_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/admin_booking_operations_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/admin_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/booking_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/application/admin_user_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/admin/audit-logs/index.dart'
    as admin_audit_list;
import '../../../../routes/api/v1/admin/bookings/index.dart'
    as admin_bookings_list;
import '../../../../routes/api/v1/admin/disputes/index.dart'
    as admin_disputes_list;
import '../../../../routes/api/v1/admin/users/index.dart' as admin_users_list;
import '../../../../routes/api/v1/bookings/[bookingId]/dispute/index.dart'
    as participant_dispute;
import '../../../helpers/account_route_test_utils.dart';
import '../../../helpers/auth_route_test_utils.dart';
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';
import '../../../helpers/payment_test_fixtures.dart';
import '../../../helpers/recording_audit_sink.dart';
import '../../../helpers/recording_notification_sink.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late ObjectId bookingId;
  late BookingDisputeService participant;
  late AdminDisputeService adminDisputes;
  late AdminUserManagementService adminUsers;
  late AdminBookingOperationsService adminBookings;
  late AuditLogService auditLogs;
  late AuthenticatedUserContext customerScoped;
  late AuthenticatedUserContext adminScoped;

  final customer = fakeAuthResult().user;
  final cleaner = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c2'),
  );
  final admin = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c3'),
    role: UserRole.admin,
    email: 'admin@example.com',
  );

  setUp(() {
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    final bookings = MemoryCollectionDocumentStore();
    final disputes = MemoryCollectionDocumentStore();
    final customers = MemoryCollectionDocumentStore();
    final cleaners = MemoryCollectionDocumentStore();
    final payments = MemoryCollectionDocumentStore();
    final auditDocs = MemoryCollectionDocumentStore();
    final users = MemoryUserRepository()
      ..users.addAll([customer, cleaner, admin]);
    customers.documents.add(
      CustomerProfile(
        id: ObjectId(),
        userId: customer.id,
        fullName: 'Pat Customer',
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      ).toDocument(),
    );
    cleaners.documents.add(
      testCleanerProfileRecord(userId: cleaner.id).toDocument(),
    );
    bookings.documents.add(
      testConfirmedBooking(
        customerId: customer.id,
        cleanerId: cleaner.id,
        id: bookingId,
      ).toDocument(),
    );
    final bookingRepo = MongoBookingRepository(documents: bookings);
    final disputeRepo = MongoDisputeRepository(documents: disputes);
    final customerRepo = MongoCustomerProfileRepository(documents: customers);
    final cleanerRepo = MongoCleanerProfileRepository(documents: cleaners);
    final paymentRepo = MongoPaymentRepository(documents: payments);
    final notifications = RecordingNotificationSink();
    final audit = RecordingAuditSink();
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
      revokeAllSessions: (_) async => 0,
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
    auditLogs = AuditLogService(
      logs: MongoAuditLogRepository(documents: auditDocs),
      clock: marketplaceTestNow,
    );
    customerScoped = AuthenticatedUserContext(
      principal: fakePrincipal(),
      currentUser: customer,
    );
    adminScoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.admin),
      currentUser: admin,
    );
  });

  RequestContext customerCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(customerScoped);
    when(() => context.read<BookingDisputeService>()).thenReturn(participant);
    return context;
  }

  RequestContext adminCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(
      () => context.read<AuthenticatedUserContext>(),
    ).thenReturn(adminScoped);
    when(() => context.read<AdminDisputeService>()).thenReturn(adminDisputes);
    when(
      () => context.read<AdminUserManagementService>(),
    ).thenReturn(adminUsers);
    when(
      () => context.read<AdminBookingOperationsService>(),
    ).thenReturn(adminBookings);
    when(() => context.read<AuditLogService>()).thenReturn(auditLogs);
    return context;
  }

  test('participant get none then create 201', () async {
    final none = await participant_dispute.onRequest(
      customerCtx(
        Request(
          'GET',
          Uri.parse(
            'http://localhost/api/v1/bookings/${bookingId.oid}/dispute',
          ),
        ),
      ),
      bookingId.oid,
    );
    expect(none.statusCode, equals(HttpStatus.ok));
    final noneBody = jsonDecode(await none.body()) as Map;
    expect((noneBody['data'] as Map)['dispute'], isNull);
    final created = await participant_dispute.onRequest(
      customerCtx(
        Request(
          'POST',
          Uri.parse(
            'http://localhost/api/v1/bookings/${bookingId.oid}/dispute',
          ),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: jsonEncode(<String, String>{
            'category': 'service_quality',
            'subject': 'Late arrival issue',
            'description':
                'The cleaner arrived more than two hours late to the job.',
          }),
        ),
      ),
      bookingId.oid,
    );
    expect(created.statusCode, equals(HttpStatus.created));
    final createdBody = jsonDecode(await created.body()) as Map;
    expect(
      ((createdBody['data'] as Map)['dispute'] as Map)['status'],
      'open',
    );
  });

  test('admin lists disputes users bookings and audit logs', () async {
    final disputes = await admin_disputes_list.onRequest(
      adminCtx(
        Request('GET', Uri.parse('http://localhost/api/v1/admin/disputes')),
      ),
    );
    expect(disputes.statusCode, equals(HttpStatus.ok));
    final users = await admin_users_list.onRequest(
      adminCtx(
        Request('GET', Uri.parse('http://localhost/api/v1/admin/users')),
      ),
    );
    expect(users.statusCode, equals(HttpStatus.ok));
    final usersBody = jsonDecode(await users.body()) as Map;
    expect(
      jsonEncode(usersBody),
      isNot(contains('password_hash')),
    );
    final bookings = await admin_bookings_list.onRequest(
      adminCtx(
        Request('GET', Uri.parse('http://localhost/api/v1/admin/bookings')),
      ),
    );
    expect(bookings.statusCode, equals(HttpStatus.ok));
    final audit = await admin_audit_list.onRequest(
      adminCtx(
        Request('GET', Uri.parse('http://localhost/api/v1/admin/audit-logs')),
      ),
    );
    expect(audit.statusCode, equals(HttpStatus.ok));
  });
}
