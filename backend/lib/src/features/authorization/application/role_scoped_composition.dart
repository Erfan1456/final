import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/data/audit_log_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/mongo_user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/current_authenticated_user_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/role_request_authorizer.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/application/cleaner_availability_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/admin_booking_operations_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/cleaner_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/application/cleaner_service_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/application/cleaner_discovery_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/admin_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/booking_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/data/dispute_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/application/earnings_settlement_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_ledger_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/finance/application/admin_finance_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/booking_cancellation_orchestrator.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/customer_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/sandbox_payment_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_refund_request_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_webhook_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/payment_provider_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/provider/sandbox_payment_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/admin_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/cleaner_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/payout_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/sandbox_payout_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_provider_event_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/payout_provider_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/provider/sandbox_payout_provider.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/admin_review_moderation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/customer_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/application/admin_user_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Process-scoped composition for role-authorized feature routes.
class RoleScopedComposition {
  RoleScopedComposition._();

  static CustomerAccountService? _customer;
  static CleanerOnboardingService? _cleaner;
  static AdminCleanerReviewService? _admin;
  static CurrentAuthenticatedUserResolver? _resolver;
  static UserRepository? _users;
  static ServiceRepository? _services;
  static CleanerServiceManagementService? _serviceManagement;
  static CleanerAvailabilityService? _availability;
  static CleanerDiscoveryService? _discovery;
  static CustomerBookingService? _customerBookings;
  static CleanerBookingService? _cleanerBookings;
  static CustomerPaymentService? _customerPayments;
  static AdminPaymentService? _adminPayments;
  static PaymentWebhookService? _paymentWebhooks;
  static SandboxPaymentSimulationService? _sandboxSimulation;
  static BookingCancellationOrchestrator? _bookingCancellation;
  static NotificationService? _notifications;
  static BookingConversationService? _conversations;
  static CustomerReviewService? _customerReviews;
  static CleanerReviewService? _cleanerReviews;
  static AdminReviewModerationService? _adminReviews;
  static AuditLogService? _audit;
  static BookingDisputeService? _bookingDisputes;
  static AdminDisputeService? _adminDisputes;
  static AdminUserManagementService? _adminUsers;
  static AdminBookingOperationsService? _adminBookings;
  static EarningsSettlementService? _earningsSettlement;
  static CleanerPayoutService? _cleanerPayouts;
  static AdminPayoutService? _adminPayouts;
  static PayoutWebhookService? _payoutWebhooks;
  static SandboxPayoutSimulationService? _sandboxPayoutSimulation;
  static AdminFinanceService? _adminFinance;

  /// Builds a [RoleRequestAuthorizer] from request providers.
  ///
  /// Tests may provide [AccessAuthenticator] and
  /// [CurrentAuthenticatedUserResolver] on the context.
  static Future<RoleRequestAuthorizer> authorizer(
    RequestContext context,
  ) async {
    final authenticator =
        _tryRead<AccessAuthenticator>(context) ??
        AccessAuthenticator(
          tokens: AccountComposition.accessTokens(context.read<ServerConfig>()),
        );
    final resolver =
        _tryRead<CurrentAuthenticatedUserResolver>(context) ??
        await _userResolver(context.read<MongoDatabase>());
    return RoleRequestAuthorizer(
      authenticator: authenticator,
      resolver: resolver,
    );
  }

  /// Shared customer profile/address service.
  static Future<CustomerAccountService> customer({
    required MongoDatabase mongo,
  }) async {
    final cached = _customer;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _customer = CustomerAccountService(
      profiles: MongoCustomerProfileRepository.fromDb(db),
      addresses: MongoAddressRepository.fromDb(db),
    );
  }

  /// Shared cleaner onboarding service.
  static Future<CleanerOnboardingService> cleaner({
    required MongoDatabase mongo,
  }) async {
    final cached = _cleaner;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _cleaner = CleanerOnboardingService(
      profiles: MongoCleanerProfileRepository.fromDb(db),
    );
  }

  /// Shared admin cleaner-review service.
  static Future<AdminCleanerReviewService> admin({
    required MongoDatabase mongo,
  }) async {
    final cached = _admin;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _admin = AdminCleanerReviewService(
      profiles: MongoCleanerProfileRepository.fromDb(db),
      users: MongoUserRepository.fromDb(db),
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared platform catalog repository.
  static Future<ServiceRepository> services({
    required MongoDatabase mongo,
  }) async {
    final cached = _services;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _services = MongoServiceRepository.fromDb(db);
  }

  /// Shared cleaner offering management.
  static Future<CleanerServiceManagementService> cleanerServices({
    required MongoDatabase mongo,
  }) async {
    final cached = _serviceManagement;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final profiles = MongoCleanerProfileRepository.fromDb(db);
    return _serviceManagement = CleanerServiceManagementService(
      policy: ApprovedCleanerPolicy(profiles: profiles),
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
    );
  }

  /// Shared cleaner availability management.
  static Future<CleanerAvailabilityService> cleanerAvailability({
    required MongoDatabase mongo,
  }) async {
    final cached = _availability;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final profiles = MongoCleanerProfileRepository.fromDb(db);
    return _availability = CleanerAvailabilityService(
      policy: ApprovedCleanerPolicy(profiles: profiles),
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
      slots: MongoAvailabilityRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
    );
  }

  /// Shared customer discovery.
  static Future<CleanerDiscoveryService> discovery({
    required MongoDatabase mongo,
  }) async {
    final cached = _discovery;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _discovery = CleanerDiscoveryService(
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
      profiles: MongoCleanerProfileRepository.fromDb(db),
      users: _users ??= MongoUserRepository.fromDb(db),
      slots: MongoAvailabilityRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
      reviews: MongoReviewRepository.fromDb(db),
    );
  }

  /// Shared customer booking service.
  static Future<CustomerBookingService> customerBookings({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _customerBookings;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final bookings = MongoBookingRepository.fromDb(db);
    return _customerBookings = CustomerBookingService(
      addresses: MongoAddressRepository.fromDb(db),
      slots: MongoAvailabilityRepository.fromDb(db),
      users: _users ??= MongoUserRepository.fromDb(db),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      services: await services(mongo: mongo),
      offerings: MongoCleanerServiceRepository.fromDb(db),
      bookings: bookings,
      cancellation: await bookingCancellation(mongo: mongo, config: config),
      notifications: await notifications(mongo: mongo),
    );
  }

  /// Shared cleaner booking/job service.
  static Future<CleanerBookingService> cleanerBookings({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _cleanerBookings;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _cleanerBookings = CleanerBookingService(
      bookings: MongoBookingRepository.fromDb(db),
      customerProfiles: MongoCustomerProfileRepository.fromDb(db),
      cancellation: await bookingCancellation(mongo: mongo, config: config),
      notifications: await notifications(mongo: mongo),
      earnings: await earningsSettlement(mongo: mongo, config: config),
    );
  }

  /// Shared customer payment service.
  static Future<CustomerPaymentService> customerPayments({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _customerPayments;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _customerPayments = CustomerPaymentService(
      bookings: wired.bookings,
      payments: wired.payments,
      provider: wired.provider,
      config: config,
    );
  }

  /// Shared admin payment service.
  static Future<AdminPaymentService> adminPayments({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _adminPayments;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _adminPayments = AdminPaymentService(
      payments: wired.payments,
      events: wired.events,
      refundRequests: wired.refundRequests,
      bookings: wired.bookings,
      webhooks: wired.webhooks,
      provider: wired.provider,
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared webhook processor. Used by HMAC webhook routes.
  static Future<PaymentWebhookService> paymentWebhooks({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _paymentWebhooks;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _paymentWebhooks = wired.webhooks;
  }

  /// Development-only sandbox simulator.
  static Future<SandboxPaymentSimulationService> sandboxSimulation({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _sandboxSimulation;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _sandboxSimulation = SandboxPaymentSimulationService(
      config: config,
      payments: wired.payments,
      webhooks: wired.webhooks,
      sandbox: wired.provider is SandboxPaymentProvider
          ? wired.provider! as SandboxPaymentProvider
          : null,
    );
  }

  /// Payment-aware booking cancellation.
  static Future<BookingCancellationOrchestrator> bookingCancellation({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _bookingCancellation;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _bookingCancellation = BookingCancellationOrchestrator(
      bookings: wired.bookings,
      payments: wired.payments,
      webhooks: wired.webhooks,
      provider: wired.provider,
    );
  }

  /// Shared in-app notification service.
  static Future<NotificationService> notifications({
    required MongoDatabase mongo,
  }) async {
    final cached = _notifications;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _notifications = NotificationService(
      notifications: MongoNotificationRepository.fromDb(db),
    );
  }

  /// Shared booking conversation service.
  static Future<BookingConversationService> conversations({
    required MongoDatabase mongo,
  }) async {
    final cached = _conversations;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _conversations = BookingConversationService(
      bookings: MongoBookingRepository.fromDb(db),
      conversations: MongoConversationRepository.fromDb(db),
      members: MongoConversationMemberRepository.fromDb(db),
      messages: MongoMessageRepository.fromDb(db),
      customerProfiles: MongoCustomerProfileRepository.fromDb(db),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      notifications: await notifications(mongo: mongo),
    );
  }

  /// Shared customer review service.
  static Future<CustomerReviewService> customerReviews({
    required MongoDatabase mongo,
  }) async {
    final cached = _customerReviews;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _customerReviews = CustomerReviewService(
      bookings: MongoBookingRepository.fromDb(db),
      reviews: MongoReviewRepository.fromDb(db),
      notifications: await notifications(mongo: mongo),
    );
  }

  /// Shared cleaner review list service.
  static Future<CleanerReviewService> cleanerReviews({
    required MongoDatabase mongo,
  }) async {
    final cached = _cleanerReviews;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _cleanerReviews = CleanerReviewService(
      reviews: MongoReviewRepository.fromDb(db),
    );
  }

  /// Shared admin review moderation.
  static Future<AdminReviewModerationService> adminReviews({
    required MongoDatabase mongo,
  }) async {
    final cached = _adminReviews;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _adminReviews = AdminReviewModerationService(
      reviews: MongoReviewRepository.fromDb(db),
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared append-only audit log service.
  static Future<AuditLogService> audit({required MongoDatabase mongo}) async {
    final cached = _audit;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _audit = AuditLogService(
      logs: MongoAuditLogRepository.fromDb(db),
    );
  }

  /// Shared participant dispute service.
  static Future<BookingDisputeService> bookingDisputes({
    required MongoDatabase mongo,
  }) async {
    final cached = _bookingDisputes;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _bookingDisputes = BookingDisputeService(
      bookings: MongoBookingRepository.fromDb(db),
      disputes: MongoDisputeRepository.fromDb(db),
      customerProfiles: MongoCustomerProfileRepository.fromDb(db),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      notifications: await notifications(mongo: mongo),
    );
  }

  /// Shared admin dispute queue.
  static Future<AdminDisputeService> adminDisputes({
    required MongoDatabase mongo,
  }) async {
    final cached = _adminDisputes;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _adminDisputes = AdminDisputeService(
      disputes: MongoDisputeRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
      customerProfiles: MongoCustomerProfileRepository.fromDb(db),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      notifications: await notifications(mongo: mongo),
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared admin user moderation.
  static Future<AdminUserManagementService> adminUsers({
    required MongoDatabase mongo,
  }) async {
    final cached = _adminUsers;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final sessions = AuthSessionService(
      sessions: MongoUserSessionRepository.fromDb(db),
    );
    return _adminUsers = AdminUserManagementService(
      users: MongoUserRepository.fromDb(db),
      customerProfiles: MongoCustomerProfileRepository.fromDb(db),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      bookings: MongoBookingRepository.fromDb(db),
      payments: MongoPaymentRepository.fromDb(db),
      disputes: MongoDisputeRepository.fromDb(db),
      revokeAllSessions: sessions.revokeAllForUser,
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared admin booking operations.
  static Future<AdminBookingOperationsService> adminBookings({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _adminBookings;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _adminBookings = AdminBookingOperationsService(
      bookings: wired.bookings,
      payments: wired.payments,
      disputes: MongoDisputeRepository.fromDb(await _requireDb(mongo)),
      customerProfiles: MongoCustomerProfileRepository.fromDb(
        await _requireDb(mongo),
      ),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(
        await _requireDb(mongo),
      ),
      cancellation: await bookingCancellation(mongo: mongo, config: config),
      notifications: await notifications(mongo: mongo),
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared earnings settlement for booking completion and payment webhooks.
  static Future<EarningsSettlementService> earningsSettlement({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _earningsSettlement;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _earningsSettlement = wired.earnings;
  }

  /// Shared cleaner earnings and payout-request service.
  static Future<CleanerPayoutService> cleanerPayouts({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _cleanerPayouts;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _cleanerPayouts = CleanerPayoutService(
      ledger: wired.ledger,
      payouts: wired.payouts,
    );
  }

  /// Shared admin payout operations.
  static Future<AdminPayoutService> adminPayouts({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _adminPayouts;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    final db = await _requireDb(mongo);
    return _adminPayouts = AdminPayoutService(
      payouts: wired.payouts,
      events: wired.payoutEvents,
      cleanerPayouts: await cleanerPayouts(mongo: mongo, config: config),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      provider: wired.payoutProvider,
      notifications: await notifications(mongo: mongo),
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared payout webhook processor.
  static Future<PayoutWebhookService> payoutWebhooks({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _payoutWebhooks;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _payoutWebhooks = wired.payoutWebhooks;
  }

  /// Development-only sandbox payout simulator.
  static Future<SandboxPayoutSimulationService> sandboxPayoutSimulation({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _sandboxPayoutSimulation;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    return _sandboxPayoutSimulation = SandboxPayoutSimulationService(
      config: config,
      payouts: wired.payouts,
      webhooks: wired.payoutWebhooks,
      sandbox: wired.payoutProvider is SandboxPayoutProvider
          ? wired.payoutProvider! as SandboxPayoutProvider
          : null,
      audit: await audit(mongo: mongo),
    );
  }

  /// Shared admin finance and reconciliation.
  static Future<AdminFinanceService> adminFinance({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _adminFinance;
    if (cached != null) {
      return cached;
    }
    final wired = await _paymentStack(mongo: mongo, config: config);
    final db = await _requireDb(mongo);
    return _adminFinance = AdminFinanceService(
      ledger: wired.ledger,
      payouts: wired.payouts,
      bookings: wired.bookings,
      payments: wired.payments,
      cleanerPayouts: await cleanerPayouts(mongo: mongo, config: config),
      cleanerProfiles: MongoCleanerProfileRepository.fromDb(db),
      users: _users ??= MongoUserRepository.fromDb(db),
    );
  }

  static _PaymentStack? _paymentStackCache;

  static Future<_PaymentStack> _paymentStack({
    required MongoDatabase mongo,
    required ServerConfig config,
  }) async {
    final cached = _paymentStackCache;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    final payments = MongoPaymentRepository.fromDb(db);
    final events = MongoPaymentWebhookEventRepository.fromDb(db);
    final refundRequests = MongoPaymentRefundRequestRepository.fromDb(db);
    final bookings = MongoBookingRepository.fromDb(db);
    final ledger = MongoEarningsLedgerRepository.fromDb(db);
    final payouts = MongoPayoutRepository.fromDb(db);
    final payoutEvents = MongoPayoutProviderEventRepository.fromDb(db);
    final provider = const PaymentProviderResolver().resolve(config);
    final payoutProvider = const PayoutProviderResolver().resolve(config);
    final earnings = EarningsSettlementService(
      config: config,
      bookings: bookings,
      payments: payments,
      ledger: ledger,
    );
    final webhooks = PaymentWebhookService(
      provider: provider,
      payments: payments,
      events: events,
      notifications: await notifications(mongo: mongo),
      earnings: earnings,
    );
    final payoutWebhooks = PayoutWebhookService(
      provider: payoutProvider,
      payouts: payouts,
      events: payoutEvents,
      notifications: await notifications(mongo: mongo),
    );
    return _paymentStackCache = _PaymentStack(
      payments: payments,
      events: events,
      refundRequests: refundRequests,
      bookings: bookings,
      provider: provider,
      webhooks: webhooks,
      ledger: ledger,
      earnings: earnings,
      payouts: payouts,
      payoutEvents: payoutEvents,
      payoutProvider: payoutProvider,
      payoutWebhooks: payoutWebhooks,
    );
  }

  static Future<CurrentAuthenticatedUserResolver> _userResolver(
    MongoDatabase mongo,
  ) async {
    final cached = _resolver;
    if (cached != null) {
      return cached;
    }
    final db = await _requireDb(mongo);
    return _resolver = CurrentAuthenticatedUserResolver(
      users: _users ??= MongoUserRepository.fromDb(db),
    );
  }

  static Future<Db> _requireDb(MongoDatabase mongo) async {
    if (!mongo.isConfigured) {
      throw const AuthenticationConfigurationException();
    }
    try {
      await mongo.connect();
    } catch (_) {
      throw const AuthenticationConfigurationException();
    }
    final db = mongo.db;
    if (db == null) {
      throw const AuthenticationConfigurationException();
    }
    return db;
  }

  static T? _tryRead<T>(RequestContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}

class _PaymentStack {
  const _PaymentStack({
    required this.payments,
    required this.events,
    required this.refundRequests,
    required this.bookings,
    required this.provider,
    required this.webhooks,
    required this.ledger,
    required this.earnings,
    required this.payouts,
    required this.payoutEvents,
    required this.payoutProvider,
    required this.payoutWebhooks,
  });

  final PaymentRepository payments;
  final PaymentWebhookEventRepository events;
  final PaymentRefundRequestRepository refundRequests;
  final BookingRepository bookings;
  final PaymentProvider? provider;
  final PaymentWebhookService webhooks;
  final EarningsLedgerRepository ledger;
  final EarningsSettlementService earnings;
  final PayoutRepository payouts;
  final PayoutProviderEventRepository payoutEvents;
  final PayoutProvider? payoutProvider;
  final PayoutWebhookService payoutWebhooks;
}
