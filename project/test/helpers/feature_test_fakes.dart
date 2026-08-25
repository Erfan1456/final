import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/availability_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_models.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/presentation/catalog_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/comparison_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_models.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/cleaner_reviews_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_booking_models.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_user_models.dart';
import 'package:home_cleaning_marketplace/features/admin/data/audit_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_log_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_operations_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_management_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';

class SeededCustomerProfileController extends CustomerProfileController {
  SeededCustomerProfileController(this._seed);

  final CustomerProfileState _seed;
  int saveCalls = 0;

  @override
  CustomerProfileState build() => _seed;

  @override
  Future<void> load() async {}

  @override
  Future<bool> save({
    required String fullName,
    required String? phoneE164,
  }) async {
    saveCalls += 1;
    return true;
  }
}

class SeededAddressController extends AddressController {
  SeededAddressController(this._seed);

  final AddressListState _seed;
  int createCalls = 0;
  int deleteCalls = 0;
  int defaultCalls = 0;

  @override
  AddressListState build() => _seed;

  @override
  Future<void> load() async {}

  int updateCalls = 0;

  @override
  Future<bool> create({
    required String label,
    required String line1,
    required String? line2,
    required String city,
    required String region,
    required String postalCode,
    required String countryCode,
  }) async {
    createCalls += 1;
    return true;
  }

  @override
  Future<bool> update({
    required String id,
    required String label,
    required String line1,
    required String? line2,
    required String city,
    required String region,
    required String postalCode,
    required String countryCode,
  }) async {
    updateCalls += 1;
    return true;
  }

  @override
  Future<bool> delete(String id) async {
    deleteCalls += 1;
    return true;
  }

  @override
  Future<bool> setDefault(String id) async {
    defaultCalls += 1;
    return true;
  }
}

class SeededCleanerOnboardingController extends CleanerOnboardingController {
  SeededCleanerOnboardingController(this._seed);

  final CleanerOnboardingState _seed;
  int saveCalls = 0;
  int submitCalls = 0;

  @override
  CleanerOnboardingState build() => _seed;

  @override
  Future<void> load() async {}

  @override
  Future<bool> save(Map<String, Object?> body) async {
    saveCalls += 1;
    return true;
  }

  @override
  Future<bool> submit() async {
    submitCalls += 1;
    return true;
  }
}

class SeededAdminCleanerReviewController extends AdminCleanerReviewController {
  SeededAdminCleanerReviewController(this._seed);

  final AdminCleanerReviewState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;

  @override
  AdminCleanerReviewState build() => _seed;

  @override
  Future<void> load({String? status}) async {
    loadCalls += 1;
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String userId) async {}

  @override
  Future<bool> approve(String userId) async {
    approveCalls += 1;
    return true;
  }

  @override
  Future<bool> reject(String userId, String reason) async {
    rejectCalls += 1;
    return true;
  }
}

class SeededCatalogController extends CatalogController {
  SeededCatalogController(this._seed);

  final CatalogState _seed;

  @override
  CatalogState build() => _seed;

  @override
  Future<void> load() async {}
}

class SeededCleanerServiceController extends CleanerServiceController {
  SeededCleanerServiceController(this._seed);

  final CleanerServiceState _seed;
  int saveCalls = 0;
  int deactivateCalls = 0;

  @override
  CleanerServiceState build() => _seed;

  @override
  Future<void> load() async {}

  @override
  Future<bool> save({
    required String serviceId,
    required int hourlyRateMinor,
    required String currencyCode,
    required bool isActive,
  }) async {
    saveCalls += 1;
    state = state.copyWith(saving: true);
    return true;
  }

  @override
  Future<bool> deactivate(String serviceId) async {
    deactivateCalls += 1;
    return true;
  }
}

class SeededAvailabilityController extends AvailabilityController {
  SeededAvailabilityController(this._seed);

  final AvailabilityState _seed;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  AvailabilityState build() => _seed;

  @override
  Future<void> load() async {}

  @override
  Future<bool> create({
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    createCalls += 1;
    return true;
  }

  @override
  Future<bool> update({
    required String slotId,
    required String serviceId,
    required String startAt,
    required String endAt,
  }) async {
    updateCalls += 1;
    return true;
  }

  @override
  Future<bool> delete(String slotId) async {
    deleteCalls += 1;
    return true;
  }
}

class SeededDiscoveryController extends DiscoveryController {
  SeededDiscoveryController(this._seed);

  final DiscoveryState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  DiscoveryFilters? lastFilters;

  @override
  DiscoveryState build() => _seed;

  @override
  Future<void> load({DiscoveryFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = DiscoveryState(
        loading: false,
        items: state.items,
        nextCursor: state.nextCursor,
        filters: filters,
      );
    }
  }

  @override
  Future<void> applyFilters(DiscoveryFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String cleanerUserId) async {
    loadDetailCalls += 1;
  }
}

class SeededComparisonController extends ComparisonController {
  SeededComparisonController(this._seed);

  final ComparisonState _seed;

  @override
  ComparisonState build() => _seed;
}

class SeededCustomerBookingController extends CustomerBookingController {
  SeededCustomerBookingController(this._seed);

  final CustomerBookingState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int submitCalls = 0;
  int cancelCalls = 0;
  int beginAttemptCalls = 0;
  BookingStatus? lastStatus;
  String? lastSubmitSlotId;
  String? lastSubmitAddressId;
  String? lastNotes;

  @override
  CustomerBookingState build() => _seed;

  @override
  void beginSubmitAttempt({String Function()? keyFactory}) {
    beginAttemptCalls += 1;
    super.beginSubmitAttempt(
      keyFactory: keyFactory ?? () => 'test-idempotency-key-aa',
    );
  }

  @override
  Future<void> load({BookingStatus? status, bool clearFilter = false}) async {
    loadCalls += 1;
    lastStatus = clearFilter ? null : status;
    state = state.copyWith(
      loading: false,
      statusFilter: lastStatus,
      clearFilter: lastStatus == null,
    );
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String bookingId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<CustomerBooking?> submit({
    required String availabilitySlotId,
    required String addressId,
    String? customerNotes,
  }) async {
    if (state.submitting) {
      return state.submittedBooking;
    }
    submitCalls += 1;
    lastSubmitSlotId = availabilitySlotId;
    lastSubmitAddressId = addressId;
    lastNotes = customerNotes;
    state = state.copyWith(submitting: true);
    final booking = testCustomerBooking();
    state = state.copyWith(submitting: false, submittedBooking: booking);
    return booking;
  }

  @override
  Future<bool> cancel(String bookingId, {String? reason}) async {
    cancelCalls += 1;
    return true;
  }
}

class SeededCustomerPaymentController extends CustomerPaymentController {
  SeededCustomerPaymentController(this._seed);

  final CustomerPaymentState _seed;
  int loadCalls = 0;
  int startCalls = 0;
  int retryCalls = 0;
  int cancelCalls = 0;
  int simulateSuccessCalls = 0;
  int simulateFailureCalls = 0;
  int beginAttemptCalls = 0;

  @override
  CustomerPaymentState build() => _seed;

  @override
  void beginAttempt({String Function()? keyFactory}) {
    beginAttemptCalls += 1;
    super.beginAttempt(
      keyFactory: keyFactory ?? () => 'test-payment-idem-key1',
    );
  }

  @override
  Future<void> load(String bookingId) async {
    loadCalls += 1;
  }

  @override
  Future<PaymentAttempt?> startPayment(
    String bookingId, {
    String Function()? keyFactory,
  }) async {
    if (state.submitting) {
      return state.current;
    }
    startCalls += 1;
    state = state.copyWith(submitting: true);
    return state.current;
  }

  @override
  Future<PaymentAttempt?> retryPayment(String bookingId) async {
    retryCalls += 1;
    beginAttempt();
    return startPayment(bookingId);
  }

  @override
  Future<bool> cancelPayment(String bookingId) async {
    cancelCalls += 1;
    return true;
  }

  @override
  Future<bool> simulateSuccess(String bookingId, String paymentId) async {
    simulateSuccessCalls += 1;
    return true;
  }

  @override
  Future<bool> simulateFailure(String bookingId, String paymentId) async {
    simulateFailureCalls += 1;
    return true;
  }
}

class SeededAdminPaymentController extends AdminPaymentController {
  SeededAdminPaymentController(this._seed);

  final AdminPaymentState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int refundCalls = 0;
  int beginRefundCalls = 0;
  AdminPaymentFilters? lastFilters;
  String? lastRefundReason;
  int? lastRefundAmount;
  String? lastRefundKey;

  @override
  AdminPaymentState build() => _seed;

  @override
  void beginRefundAttempt({String Function()? keyFactory}) {
    beginRefundCalls += 1;
    super.beginRefundAttempt(
      keyFactory: keyFactory ?? () => 'test-refund-idem-key1',
    );
  }

  @override
  Future<void> load({AdminPaymentFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = state.copyWith(filters: filters, loading: false);
    }
  }

  @override
  Future<void> applyFilters(AdminPaymentFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String paymentId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<bool> refund({
    required String paymentId,
    required String reason,
    int? amountMinor,
    String Function()? keyFactory,
  }) async {
    if (state.saving) {
      return false;
    }
    refundCalls += 1;
    lastRefundReason = reason;
    lastRefundAmount = amountMinor;
    lastRefundKey = state.refundIdempotencyKey;
    return true;
  }
}

class SeededCleanerBookingController extends CleanerBookingController {
  SeededCleanerBookingController(this._seed);

  final CleanerBookingState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int acceptCalls = 0;
  int declineCalls = 0;
  int cancelCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;
  String? lastReason;
  BookingStatus? lastStatus;

  @override
  CleanerBookingState build() => _seed;

  @override
  Future<void> load({BookingStatus? status, bool clearFilter = false}) async {
    loadCalls += 1;
    lastStatus = clearFilter ? null : status;
    state = state.copyWith(
      loading: false,
      statusFilter: lastStatus,
      clearFilter: lastStatus == null,
    );
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String bookingId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<bool> accept(String bookingId) async {
    acceptCalls += 1;
    return true;
  }

  @override
  Future<bool> decline(String bookingId, {required String reason}) async {
    declineCalls += 1;
    lastReason = reason;
    return true;
  }

  @override
  Future<bool> cancel(String bookingId, {required String reason}) async {
    cancelCalls += 1;
    lastReason = reason;
    return true;
  }

  @override
  Future<bool> start(String bookingId) async {
    startCalls += 1;
    return true;
  }

  @override
  Future<bool> complete(String bookingId) async {
    completeCalls += 1;
    return true;
  }
}

class SeededBookingChatController extends BookingChatController {
  SeededBookingChatController(this._seed);

  final BookingChatState _seed;
  int loadCalls = 0;
  int loadOlderCalls = 0;
  int sendCalls = 0;
  int markReadCalls = 0;
  int startPollingCalls = 0;
  int stopPollingCalls = 0;

  @override
  BookingChatState build() => _seed;

  @override
  Future<void> load(String bookingId) async {
    loadCalls += 1;
  }

  @override
  Future<void> loadOlder() async {
    loadOlderCalls += 1;
  }

  @override
  Future<void> send({String Function()? keyFactory}) async {
    if (state.sending) {
      return;
    }
    sendCalls += 1;
  }

  @override
  Future<void> markRead() async {
    markReadCalls += 1;
  }

  @override
  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    startPollingCalls += 1;
  }

  @override
  void stopPolling() {
    stopPollingCalls += 1;
  }
}

class SeededNotificationController extends NotificationController {
  SeededNotificationController(this._seed);

  final NotificationState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int markOneCalls = 0;
  int markAllCalls = 0;
  int unreadFilterCalls = 0;
  String? lastMarkedId;

  @override
  NotificationState build() => _seed;

  @override
  Future<void> load({bool? unreadOnly}) async {
    loadCalls += 1;
    if (unreadOnly != null) {
      state = state.copyWith(unreadOnly: unreadOnly, loading: false);
    }
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> setUnreadFilter(bool unreadOnly) {
    unreadFilterCalls += 1;
    return load(unreadOnly: unreadOnly);
  }

  @override
  Future<void> refreshUnreadCount() async {}

  @override
  Future<void> markOne(String notificationId) async {
    markOneCalls += 1;
    lastMarkedId = notificationId;
  }

  @override
  Future<void> markAll() async {
    markAllCalls += 1;
  }
}

class SeededCustomerReviewController extends CustomerReviewController {
  SeededCustomerReviewController(this._seed);

  final CustomerReviewState _seed;
  int loadCalls = 0;
  int saveCalls = 0;
  int? lastRating;
  String? lastComment;

  @override
  CustomerReviewState build() => _seed;

  @override
  Future<void> load(String bookingId) async {
    loadCalls += 1;
  }

  @override
  Future<bool> save({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    if (state.saving) {
      return false;
    }
    saveCalls += 1;
    lastRating = rating;
    lastComment = comment;
    return true;
  }
}

class SeededCleanerReviewsController extends CleanerReviewsController {
  SeededCleanerReviewsController(this._seed);

  final CleanerReviewsState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  String? lastStatus;

  @override
  CleanerReviewsState build() => _seed;

  @override
  Future<void> load({String? status, bool clearStatus = false}) async {
    loadCalls += 1;
    lastStatus = clearStatus ? null : status;
    state = state.copyWith(
      loading: false,
      status: lastStatus,
      clearStatus: lastStatus == null,
    );
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }
}

class SeededAdminReviewController extends AdminReviewController {
  SeededAdminReviewController(this._seed);

  final AdminReviewState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int hideCalls = 0;
  int unhideCalls = 0;
  AdminReviewFilters? lastFilters;
  String? lastHideReason;

  @override
  AdminReviewState build() => _seed;

  @override
  Future<void> load({AdminReviewFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = state.copyWith(filters: filters, loading: false);
    }
  }

  @override
  Future<void> applyFilters(AdminReviewFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String reviewId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<bool> hide({required String reviewId, required String reason}) async {
    if (state.saving) {
      return false;
    }
    hideCalls += 1;
    lastHideReason = reason;
    return true;
  }

  @override
  Future<bool> unhide(String reviewId) async {
    unhideCalls += 1;
    return true;
  }
}

class SeededBookingDisputeController extends BookingDisputeController {
  SeededBookingDisputeController(this._seed);

  final BookingDisputeState _seed;
  int loadCalls = 0;
  int createCalls = 0;
  int closeCalls = 0;
  String? lastSubject;
  String? lastDescription;
  String? lastCategory;

  @override
  BookingDisputeState build() => _seed;

  @override
  Future<void> load(String bookingId) async {
    loadCalls += 1;
  }

  @override
  Future<bool> create({
    required String bookingId,
    required String category,
    required String subject,
    required String description,
  }) async {
    createCalls += 1;
    lastCategory = category;
    lastSubject = subject;
    lastDescription = description;
    return true;
  }

  @override
  Future<bool> close(String bookingId) async {
    closeCalls += 1;
    return true;
  }
}

class SeededAdminDisputeController extends AdminDisputeController {
  SeededAdminDisputeController(this._seed);

  final AdminDisputeState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int startReviewCalls = 0;
  int resolveCalls = 0;
  int closeCalls = 0;
  String? lastResolution;
  AdminDisputeFilters? lastFilters;

  @override
  AdminDisputeState build() => _seed;

  @override
  Future<void> load({AdminDisputeFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = state.copyWith(filters: filters, loading: false);
    }
  }

  @override
  Future<void> applyFilters(AdminDisputeFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String disputeId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<bool> startReview(String disputeId) async {
    startReviewCalls += 1;
    return true;
  }

  @override
  Future<bool> resolve({
    required String disputeId,
    required String resolution,
  }) async {
    resolveCalls += 1;
    lastResolution = resolution;
    return true;
  }

  @override
  Future<bool> close(String disputeId) async {
    closeCalls += 1;
    return true;
  }
}

class SeededAdminUserManagementController
    extends AdminUserManagementController {
  SeededAdminUserManagementController(this._seed);

  final AdminUserManagementState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int suspendCalls = 0;
  int reactivateCalls = 0;
  int deactivateCalls = 0;
  String? lastReason;
  AdminUserFilters? lastFilters;

  @override
  AdminUserManagementState build() => _seed;

  @override
  Future<void> load({AdminUserFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = state.copyWith(filters: filters, loading: false);
    }
  }

  @override
  Future<void> applyFilters(AdminUserFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String userId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<bool> suspend({required String userId, required String reason}) async {
    suspendCalls += 1;
    lastReason = reason;
    return true;
  }

  @override
  Future<bool> reactivate(String userId) async {
    reactivateCalls += 1;
    return true;
  }

  @override
  Future<bool> deactivate({
    required String userId,
    required String reason,
  }) async {
    deactivateCalls += 1;
    lastReason = reason;
    return true;
  }
}

class SeededAdminBookingOperationsController
    extends AdminBookingOperationsController {
  SeededAdminBookingOperationsController(this._seed);

  final AdminBookingOperationsState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  int cancelCalls = 0;
  String? lastReason;
  AdminBookingFilters? lastFilters;

  @override
  AdminBookingOperationsState build() => _seed;

  @override
  Future<void> load({AdminBookingFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = state.copyWith(filters: filters, loading: false);
    }
  }

  @override
  Future<void> applyFilters(AdminBookingFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String bookingId) async {
    loadDetailCalls += 1;
  }

  @override
  Future<bool> cancel({
    required String bookingId,
    required String reason,
  }) async {
    cancelCalls += 1;
    lastReason = reason;
    return true;
  }
}

class SeededAdminAuditLogController extends AdminAuditLogController {
  SeededAdminAuditLogController(this._seed);

  final AdminAuditLogState _seed;
  int loadCalls = 0;
  int loadMoreCalls = 0;
  int loadDetailCalls = 0;
  AdminAuditFilters? lastFilters;

  @override
  AdminAuditLogState build() => _seed;

  @override
  Future<void> load({AdminAuditFilters? filters}) async {
    loadCalls += 1;
    lastFilters = filters ?? state.filters;
    if (filters != null) {
      state = state.copyWith(filters: filters, loading: false);
    }
  }

  @override
  Future<void> applyFilters(AdminAuditFilters filters) {
    return load(filters: filters);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }

  @override
  Future<void> loadDetail(String auditLogId) async {
    loadDetailCalls += 1;
  }
}

CustomerProfile testCustomerProfile() {
  final created = DateTime.utc(2026, 8, 25, 12);
  return CustomerProfile(
    id: '507f1f77bcf86cd799439021',
    userId: '507f1f77bcf86cd799439011',
    fullName: 'Test Customer',
    phoneE164: '+15555550100',
    createdAt: created,
    updatedAt: created,
  );
}

Address testAddress({bool isDefault = false}) {
  final created = DateTime.utc(2026, 8, 25, 12);
  return Address(
    id: '507f1f77bcf86cd799439031',
    label: 'Home',
    line1: '1 Test Street',
    city: 'Dhaka',
    region: 'Dhaka',
    postalCode: '1205',
    countryCode: 'BD',
    isDefault: isDefault,
    createdAt: created,
    updatedAt: created,
  );
}

CleanerProfile testCleanerProfile({
  OnboardingStatus status = OnboardingStatus.draft,
  String? rejectionReason,
}) {
  final created = DateTime.utc(2026, 8, 25, 12);
  return CleanerProfile(
    id: '507f1f77bcf86cd799439041',
    userId: '507f1f77bcf86cd799439011',
    fullName: 'Test Cleaner',
    bio: 'Experienced residential cleaner for apartments.',
    yearsExperience: 3,
    serviceArea: 'Dhaka North',
    onboardingStatus: status,
    rejectionReason: rejectionReason,
    createdAt: created,
    updatedAt: created,
  );
}

AdminCleanerApplicationSummary testAdminSummary() {
  return AdminCleanerApplicationSummary(
    id: '507f1f77bcf86cd799439041',
    userId: '507f1f77bcf86cd799439077',
    fullName: 'Pending Cleaner',
    email: 'pending.cleaner@example.com',
    onboardingStatus: OnboardingStatus.pending,
    submittedAt: DateTime.utc(2026, 8, 25, 12),
  );
}

List<dynamic> featureControllerOverrides() {
  return [
    customerProfileControllerProvider.overrideWith(
      () => SeededCustomerProfileController(
        const CustomerProfileState(loading: false),
      ),
    ),
    addressControllerProvider.overrideWith(
      () => SeededAddressController(const AddressListState(loading: false)),
    ),
    cleanerOnboardingControllerProvider.overrideWith(
      () => SeededCleanerOnboardingController(
        const CleanerOnboardingState(loading: false),
      ),
    ),
    adminCleanerReviewControllerProvider.overrideWith(
      () => SeededAdminCleanerReviewController(
        const AdminCleanerReviewState(loading: false),
      ),
    ),
    catalogControllerProvider.overrideWith(
      () => SeededCatalogController(
        CatalogState(loading: false, items: [testMarketplaceService()]),
      ),
    ),
    cleanerServiceControllerProvider.overrideWith(
      () => SeededCleanerServiceController(
        const CleanerServiceState(loading: false),
      ),
    ),
    availabilityControllerProvider.overrideWith(
      () =>
          SeededAvailabilityController(const AvailabilityState(loading: false)),
    ),
    discoveryControllerProvider.overrideWith(
      () => SeededDiscoveryController(const DiscoveryState(loading: false)),
    ),
    comparisonControllerProvider.overrideWith(
      () => SeededComparisonController(const ComparisonState()),
    ),
    customerBookingControllerProvider.overrideWith(
      () => SeededCustomerBookingController(
        const CustomerBookingState(loading: false),
      ),
    ),
    cleanerBookingControllerProvider.overrideWith(
      () => SeededCleanerBookingController(
        const CleanerBookingState(loading: false),
      ),
    ),
    customerPaymentControllerProvider.overrideWith(
      () => SeededCustomerPaymentController(
        const CustomerPaymentState(loading: false),
      ),
    ),
    adminPaymentControllerProvider.overrideWith(
      () =>
          SeededAdminPaymentController(const AdminPaymentState(loading: false)),
    ),
    bookingChatControllerProvider.overrideWith(
      () => SeededBookingChatController(const BookingChatState(loading: false)),
    ),
    notificationControllerProvider.overrideWith(
      () =>
          SeededNotificationController(const NotificationState(loading: false)),
    ),
    customerReviewControllerProvider.overrideWith(
      () => SeededCustomerReviewController(
        const CustomerReviewState(loading: false),
      ),
    ),
    cleanerReviewsControllerProvider.overrideWith(
      () => SeededCleanerReviewsController(
        const CleanerReviewsState(loading: false),
      ),
    ),
    adminReviewControllerProvider.overrideWith(
      () => SeededAdminReviewController(const AdminReviewState(loading: false)),
    ),
    bookingDisputeControllerProvider.overrideWith(
      () => SeededBookingDisputeController(
        const BookingDisputeState(loading: false),
      ),
    ),
    adminDisputeControllerProvider.overrideWith(
      () =>
          SeededAdminDisputeController(const AdminDisputeState(loading: false)),
    ),
    adminUserManagementControllerProvider.overrideWith(
      () => SeededAdminUserManagementController(
        const AdminUserManagementState(loading: false),
      ),
    ),
    adminBookingOperationsControllerProvider.overrideWith(
      () => SeededAdminBookingOperationsController(
        const AdminBookingOperationsState(loading: false),
      ),
    ),
    adminAuditLogControllerProvider.overrideWith(
      () => SeededAdminAuditLogController(
        const AdminAuditLogState(loading: false),
      ),
    ),
  ];
}

MarketplaceService testMarketplaceService({
  String id = '507f1f77bcf86cd799439051',
  String slug = 'home-cleaning',
  String name = 'Home Cleaning',
}) {
  return MarketplaceService(
    id: id,
    slug: slug,
    name: name,
    description: 'Hourly professional home cleaning.',
    billingModel: BillingModel.hourly,
  );
}

CleanerServiceOffering testCleanerServiceOffering({
  bool isActive = true,
  int hourlyRateMinor = 250000,
  String currencyCode = 'BDT',
}) {
  final created = DateTime.utc(2026, 8, 25, 12);
  return CleanerServiceOffering(
    id: '507f1f77bcf86cd799439061',
    service: testMarketplaceService(),
    hourlyRateMinor: hourlyRateMinor,
    currencyCode: currencyCode,
    isActive: isActive,
    createdAt: created,
    updatedAt: created,
  );
}

AvailabilitySlot testAvailabilitySlot({
  String id = '507f1f77bcf86cd799439071',
}) {
  return AvailabilitySlot(
    id: id,
    serviceId: testMarketplaceService().id,
    startAt: DateTime.utc(2026, 9, 1, 3),
    endAt: DateTime.utc(2026, 9, 1, 5),
    createdAt: DateTime.utc(2026, 8, 25, 12),
    updatedAt: DateTime.utc(2026, 8, 25, 12),
  );
}

CleanerDiscoverySummary testDiscoverySummary({
  String cleanerUserId = '507f1f77bcf86cd799439081',
  String fullName = 'Ada Cleaner',
  String currencyCode = 'BDT',
  int hourlyRateMinor = 250000,
  double? ratingAverage,
  int reviewCount = 0,
}) {
  return CleanerDiscoverySummary(
    cleanerUserId: cleanerUserId,
    fullName: fullName,
    bioExcerpt: 'Reliable cleaner for apartments.',
    yearsExperience: 4,
    serviceArea: 'Dhaka North',
    service: testMarketplaceService(),
    hourlyRateMinor: hourlyRateMinor,
    currencyCode: currencyCode,
    nextAvailableAt: DateTime.utc(2026, 9, 1, 3),
    ratingAverage: ratingAverage,
    reviewCount: reviewCount,
  );
}

CleanerDiscoveryDetail testDiscoveryDetail({
  String cleanerUserId = '507f1f77bcf86cd799439081',
  double? ratingAverage,
  int reviewCount = 0,
  List<PublicCleanerReview> reviews = const <PublicCleanerReview>[],
}) {
  return CleanerDiscoveryDetail(
    cleanerUserId: cleanerUserId,
    fullName: 'Ada Cleaner',
    bio: 'Reliable cleaner for apartments.',
    yearsExperience: 4,
    serviceArea: 'Dhaka North',
    service: testMarketplaceService(),
    hourlyRateMinor: 250000,
    currencyCode: 'BDT',
    availability: [testAvailabilitySlot()],
    ratingAverage: ratingAverage,
    reviewCount: reviewCount,
    reviews: reviews,
  );
}

CustomerBooking testCustomerBooking({
  String id = '507f1f77bcf86cd799439091',
  BookingStatus status = BookingStatus.pending,
  String startAt = '2026-09-01T03:00:00.000Z',
  String endAt = '2026-09-01T05:00:00.000Z',
}) {
  return CustomerBooking.fromJson(
    customerBookingJson(
      id: id,
      status: status.wireValue,
      startAt: startAt,
      endAt: endAt,
    ),
  );
}

CleanerBooking testCleanerBooking({
  String id = '507f1f77bcf86cd799439091',
  BookingStatus status = BookingStatus.pending,
  bool fullAddress = false,
  String startAt = '2026-09-01T03:00:00.000Z',
  String endAt = '2026-09-01T05:00:00.000Z',
}) {
  return CleanerBooking.fromJson(
    cleanerBookingJson(
      id: id,
      status: status.wireValue,
      fullAddress: fullAddress,
      startAt: startAt,
      endAt: endAt,
    ),
  );
}

Map<String, dynamic> customerProfileJson({
  String fullName = 'Test Customer',
  String? phoneE164 = '+15555550100',
  String? defaultAddressId,
}) {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd799439021',
    'user_id': '507f1f77bcf86cd799439011',
    'full_name': fullName,
    'phone_e164': phoneE164,
    'default_address_id': defaultAddressId,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> addressJson({
  String id = '507f1f77bcf86cd799439031',
  String label = 'Home',
  bool isDefault = false,
}) {
  return <String, dynamic>{
    'id': id,
    'label': label,
    'line1': '1 Test Street',
    'line2': null,
    'city': 'Dhaka',
    'region': 'Dhaka',
    'postal_code': '1205',
    'country_code': 'BD',
    'is_default': isDefault,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> cleanerProfileJson({
  String status = 'draft',
  String? rejectionReason,
  String? reviewedBy,
  String? submittedAt,
}) {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd799439041',
    'user_id': '507f1f77bcf86cd799439011',
    'full_name': 'Test Cleaner',
    'phone_e164': '+15555550101',
    'bio': 'Experienced residential cleaner for apartments.',
    'years_experience': 3,
    'service_area': 'Dhaka North',
    'onboarding_status': status,
    'submitted_at': submittedAt,
    'reviewed_at': reviewedBy == null ? null : '2026-08-25T13:00:00.000Z',
    'reviewed_by': reviewedBy,
    'rejection_reason': rejectionReason,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> adminSummaryJson() {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd799439041',
    'user_id': '507f1f77bcf86cd799439077',
    'full_name': 'Pending Cleaner',
    'email': 'pending.cleaner@example.com',
    'onboarding_status': 'pending',
    'submitted_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> marketplaceServiceJson() {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd799439051',
    'slug': 'home-cleaning',
    'name': 'Home Cleaning',
    'description': 'Hourly professional home cleaning.',
    'billing_model': 'hourly',
  };
}

Map<String, dynamic> cleanerOfferingJson({bool isActive = true}) {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd799439061',
    'service': marketplaceServiceJson(),
    'hourly_rate_minor': 250000,
    'currency_code': 'BDT',
    'is_active': isActive,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> availabilitySlotJson({
  String id = '507f1f77bcf86cd799439071',
}) {
  return <String, dynamic>{
    'id': id,
    'service_id': '507f1f77bcf86cd799439051',
    'start_at': '2026-09-01T03:00:00.000Z',
    'end_at': '2026-09-01T05:00:00.000Z',
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> discoverySummaryJson({
  String cleanerUserId = '507f1f77bcf86cd799439081',
  String fullName = 'Ada Cleaner',
}) {
  return <String, dynamic>{
    'cleaner_user_id': cleanerUserId,
    'full_name': fullName,
    'bio_excerpt': 'Reliable cleaner for apartments.',
    'years_experience': 4,
    'service_area': 'Dhaka North',
    'service': <String, dynamic>{
      'id': '507f1f77bcf86cd799439051',
      'slug': 'home-cleaning',
      'name': 'Home Cleaning',
    },
    'hourly_rate_minor': 250000,
    'currency_code': 'BDT',
    'next_available_at': '2026-09-01T03:00:00.000Z',
  };
}

Map<String, dynamic> bookingHistoryJson({
  String? fromStatus,
  String toStatus = 'pending',
  String actorRole = 'customer',
}) {
  return <String, dynamic>{
    'from_status': fromStatus,
    'to_status': toStatus,
    'actor_user_id': '507f1f77bcf86cd799439011',
    'actor_role': actorRole,
    'reason': null,
    'created_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> bookingAddressJson({required bool full}) {
  if (!full) {
    return <String, dynamic>{
      'city': 'Dhaka',
      'region': 'Dhaka',
      'country_code': 'BD',
    };
  }
  return <String, dynamic>{
    'label': 'Home',
    'line1': '1 Test Street',
    'line2': null,
    'city': 'Dhaka',
    'region': 'Dhaka',
    'postal_code': '1205',
    'country_code': 'BD',
  };
}

Map<String, dynamic> customerBookingJson({
  String id = '507f1f77bcf86cd799439091',
  String status = 'pending',
  bool idempotentReplay = false,
  String startAt = '2026-09-01T03:00:00.000Z',
  String endAt = '2026-09-01T05:00:00.000Z',
}) {
  return <String, dynamic>{
    'id': id,
    'status': status,
    'cleaner_user_id': '507f1f77bcf86cd799439081',
    'cleaner_full_name': 'Ada Cleaner',
    'service_snapshot': <String, dynamic>{
      'slug': 'home-cleaning',
      'name': 'Home Cleaning',
      'billing_model': 'hourly',
    },
    'address_snapshot': bookingAddressJson(full: true),
    'duration_minutes': 120,
    'hourly_rate_minor': 250000,
    'quoted_total_minor': 500000,
    'currency_code': 'BDT',
    'customer_notes': 'Please use the side entrance.',
    'start_at': startAt,
    'end_at': endAt,
    'accepted_at': null,
    'declined_at': null,
    'started_at': null,
    'completed_at': null,
    'cancelled_at': null,
    'status_history': [bookingHistoryJson()],
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
    'idempotent_replay': idempotentReplay,
  };
}

Map<String, dynamic> cleanerBookingJson({
  String id = '507f1f77bcf86cd799439091',
  String status = 'pending',
  bool fullAddress = false,
  String startAt = '2026-09-01T03:00:00.000Z',
  String endAt = '2026-09-01T05:00:00.000Z',
}) {
  return <String, dynamic>{
    'id': id,
    'status': status,
    'customer_display_name': 'Test Customer',
    'service_snapshot': <String, dynamic>{
      'slug': 'home-cleaning',
      'name': 'Home Cleaning',
      'billing_model': 'hourly',
    },
    'address_snapshot': bookingAddressJson(full: fullAddress),
    'duration_minutes': 120,
    'hourly_rate_minor': 250000,
    'quoted_total_minor': 500000,
    'currency_code': 'BDT',
    'customer_notes': 'Please use the side entrance.',
    'start_at': startAt,
    'end_at': endAt,
    'accepted_at': null,
    'declined_at': null,
    'started_at': null,
    'completed_at': null,
    'cancelled_at': null,
    'status_history': [bookingHistoryJson()],
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> paymentAttemptJson({
  String id = '507f1f77bcf86cd7994390d1',
  String bookingId = '507f1f77bcf86cd799439091',
  String status = 'pending',
  String provider = 'sandbox',
  int attemptNumber = 1,
  int refundedAmountMinor = 0,
  bool simulationAvailable = false,
  String? paidAt,
  String? failedAt,
  String? cancelledAt,
  String? refundedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'booking_id': bookingId,
    'provider': provider,
    'status': status,
    'amount_minor': 500000,
    'currency_code': 'BDT',
    'attempt_number': attemptNumber,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
    'paid_at': paidAt,
    'failed_at': failedAt,
    'cancelled_at': cancelledAt,
    'refunded_at': refundedAt,
    'refunded_amount_minor': refundedAmountMinor,
    if (simulationAvailable)
      'sandbox_session': <String, dynamic>{
        'payment_id': id,
        'simulation_available': true,
      },
  };
}

PaymentAttempt testPaymentAttempt({
  String status = 'pending',
  bool simulationAvailable = false,
  int refundedAmountMinor = 0,
  String? paidAt,
}) {
  return PaymentAttempt.fromJson(
    paymentAttemptJson(
      status: status,
      simulationAvailable: simulationAvailable,
      refundedAmountMinor: refundedAmountMinor,
      paidAt: paidAt,
    ),
  );
}

Map<String, dynamic> adminPaymentJson({
  String id = '507f1f77bcf86cd7994390d1',
  String status = 'paid',
}) {
  return <String, dynamic>{
    ...paymentAttemptJson(
      id: id,
      status: status,
      paidAt: '2026-08-25T12:05:00.000Z',
    ),
    'customer_user_id': '507f1f77bcf86cd799439011',
    'cleaner_user_id': '507f1f77bcf86cd799439081',
    'provider_payment_id': 'sandbox_abc',
    'provider_reference': null,
    'failure_code': null,
    'failure_message': null,
    'authorized_at': null,
    'booking_status': 'confirmed',
    'service_snapshot_name': 'Home Cleaning',
  };
}

Map<String, dynamic> webhookEventJson({
  String eventId = 'evt_1',
  String eventType = 'payment.succeeded',
  String processingStatus = 'processed',
}) {
  return <String, dynamic>{
    'provider_event_id': eventId,
    'event_type': eventType,
    'processing_status': processingStatus,
    'processed_at': '2026-08-25T12:05:00.000Z',
    'created_at': '2026-08-25T12:05:00.000Z',
  };
}

AdminPaymentSummary testAdminPaymentSummary({String status = 'paid'}) {
  return AdminPaymentSummary.fromJson(adminPaymentJson(status: status));
}

AdminPaymentDetail testAdminPaymentDetail({String status = 'paid'}) {
  return AdminPaymentDetail.fromJson(<String, dynamic>{
    'payment': adminPaymentJson(status: status),
    'events': [webhookEventJson()],
  });
}

Map<String, dynamic> conversationJson({
  String id = '507f1f77bcf86cd7994390a1',
  String bookingId = '507f1f77bcf86cd799439091',
  String bookingStatus = 'confirmed',
  bool readOnly = false,
  String otherPartyDisplayName = 'Ada Cleaner',
  String otherPartyRole = 'cleaner',
  int unreadCount = 0,
  String? lastMessagePreview = 'See you at 9.',
}) {
  return <String, dynamic>{
    'id': id,
    'booking_id': bookingId,
    'other_party_display_name': otherPartyDisplayName,
    'other_party_role': otherPartyRole,
    'booking_status': bookingStatus,
    'last_message_preview': lastMessagePreview,
    'last_message_at': '2026-08-25T12:10:00.000Z',
    'unread_count': unreadCount,
    'read_only': readOnly,
  };
}

Map<String, dynamic> chatMessageJson({
  String id = '507f1f77bcf86cd7994390b1',
  String conversationId = '507f1f77bcf86cd7994390a1',
  String senderUserId = '507f1f77bcf86cd799439011',
  String senderRole = 'customer',
  String body = 'Hello there',
  String createdAt = '2026-08-25T12:10:00.000Z',
  bool isMine = true,
}) {
  return <String, dynamic>{
    'id': id,
    'conversation_id': conversationId,
    'sender_user_id': senderUserId,
    'sender_role': senderRole,
    'body': body,
    'created_at': createdAt,
    'is_mine': isMine,
  };
}

ConversationDetail testConversationDetail({
  String bookingStatus = 'confirmed',
  bool readOnly = false,
  String otherPartyDisplayName = 'Ada Cleaner',
}) {
  return ConversationDetail.fromJson(
    conversationJson(
      bookingStatus: bookingStatus,
      readOnly: readOnly,
      otherPartyDisplayName: otherPartyDisplayName,
    ),
  );
}

ChatMessage testChatMessage({
  String id = '507f1f77bcf86cd7994390b1',
  String body = 'Hello there',
  bool isMine = true,
  String senderRole = 'customer',
}) {
  return ChatMessage.fromJson(
    chatMessageJson(id: id, body: body, isMine: isMine, senderRole: senderRole),
  );
}

Map<String, dynamic> inboxNotificationJson({
  String id = '507f1f77bcf86cd7994390c1',
  String type = 'booking_confirmed',
  String title = 'Booking confirmed',
  String body = 'Your booking was confirmed.',
  String? resourceType = 'booking',
  String? resourceId = '507f1f77bcf86cd799439091',
  String? readAt,
}) {
  return <String, dynamic>{
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'resource_type': resourceType,
    'resource_id': resourceId,
    'read_at': readAt,
    'created_at': '2026-08-25T12:00:00.000Z',
  };
}

InboxNotification testInboxNotification({
  String id = '507f1f77bcf86cd7994390c1',
  String type = 'booking_confirmed',
  String title = 'Booking confirmed',
  String body = 'Your booking was confirmed.',
  String? resourceType = 'booking',
  String? resourceId = '507f1f77bcf86cd799439091',
  String? readAt,
}) {
  return InboxNotification.fromJson(
    inboxNotificationJson(
      id: id,
      type: type,
      title: title,
      body: body,
      resourceType: resourceType,
      resourceId: resourceId,
      readAt: readAt,
    ),
  );
}

Map<String, dynamic> customerReviewJson({
  String id = '507f1f77bcf86cd7994390e1',
  String bookingId = '507f1f77bcf86cd799439091',
  int rating = 5,
  String? comment = 'Great job.',
  String moderationStatus = 'published',
}) {
  return <String, dynamic>{
    'id': id,
    'booking_id': bookingId,
    'rating': rating,
    'comment': comment,
    'moderation_status': moderationStatus,
    'verified_booking': true,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

Map<String, dynamic> cleanerReviewJson({
  String id = '507f1f77bcf86cd7994390e1',
  int rating = 5,
  String comment = 'Great job.',
  String moderationStatus = 'published',
}) {
  return <String, dynamic>{
    ...customerReviewJson(
      id: id,
      rating: rating,
      comment: comment,
      moderationStatus: moderationStatus,
    ),
    'reviewer_display_name': 'Verified customer',
  };
}

Map<String, dynamic> publicCleanerReviewJson({
  int rating = 5,
  String comment = 'Great job.',
}) {
  return <String, dynamic>{
    'rating': rating,
    'comment': comment,
    'created_at': '2026-08-25T12:00:00.000Z',
    'verified_booking': true,
    'reviewer_display_name': 'Verified customer',
  };
}

Map<String, dynamic> adminReviewJson({
  String id = '507f1f77bcf86cd7994390e1',
  int rating = 5,
  String comment = 'Great job.',
  String moderationStatus = 'published',
  String? hiddenReason,
  String? hiddenBy,
  String? hiddenAt,
}) {
  return <String, dynamic>{
    'id': id,
    'booking_id': '507f1f77bcf86cd799439091',
    'customer_user_id': '507f1f77bcf86cd799439011',
    'cleaner_user_id': '507f1f77bcf86cd799439081',
    'rating': rating,
    'comment': comment,
    'moderation_status': moderationStatus,
    'hidden_reason': hiddenReason,
    'hidden_by': hiddenBy,
    'hidden_at': hiddenAt,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
  };
}

CustomerReview testCustomerReview({
  int rating = 5,
  String moderationStatus = 'published',
}) {
  return CustomerReview.fromJson(
    customerReviewJson(rating: rating, moderationStatus: moderationStatus),
  );
}

CleanerReview testCleanerReview({String moderationStatus = 'published'}) {
  return CleanerReview.fromJson(
    cleanerReviewJson(moderationStatus: moderationStatus),
  );
}

AdminReviewSummary testAdminReviewSummary({
  String moderationStatus = 'published',
}) {
  return AdminReviewSummary.fromJson(
    adminReviewJson(moderationStatus: moderationStatus),
  );
}

AdminReviewDetail testAdminReviewDetail({
  String moderationStatus = 'published',
  String? hiddenReason,
}) {
  return AdminReviewDetail.fromJson(
    adminReviewJson(
      moderationStatus: moderationStatus,
      hiddenReason: hiddenReason,
      hiddenBy: hiddenReason == null ? null : '507f1f77bcf86cd799439099',
      hiddenAt: hiddenReason == null ? null : '2026-08-25T13:00:00.000Z',
    ),
  );
}

Map<String, dynamic> bookingDisputeJson({
  String status = 'open',
  String? resolution,
  String cleanerPublicName = 'Ada Cleaner',
}) {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd7994390d1',
    'booking_id': '507f1f77bcf86cd799439091',
    'category': 'service_quality',
    'status': status,
    'subject': 'Late arrival issue',
    'description': 'The cleaner arrived more than two hours late to the job.',
    'resolution': resolution,
    'history': <Map<String, dynamic>>[
      <String, dynamic>{
        'from_status': null,
        'to_status': 'open',
        'actor_user_id': '507f1f77bcf86cd799439011',
        'actor_role': 'customer',
        'note': null,
        'created_at': '2026-08-25T12:00:00.000Z',
      },
    ],
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
    'resolved_at': resolution == null ? null : '2026-08-25T13:00:00.000Z',
    'cleaner_public_name': cleanerPublicName,
  };
}

BookingDispute testBookingDispute({
  String status = 'open',
  String? resolution,
}) {
  return BookingDispute.fromJson(
    bookingDisputeJson(status: status, resolution: resolution),
  );
}

Map<String, dynamic> adminDisputeJson({String status = 'open'}) {
  return <String, dynamic>{
    ...bookingDisputeJson(status: status),
    'customer_user_id': '507f1f77bcf86cd799439011',
    'cleaner_user_id': '507f1f77bcf86cd799439081',
    'opened_by_user_id': '507f1f77bcf86cd799439011',
    'opened_by_role': 'customer',
    'customer_display_name': 'Pat Customer',
    'cleaner_public_name': 'Ada Cleaner',
  };
}

AdminDisputeSummary testAdminDisputeSummary({String status = 'open'}) {
  return AdminDisputeSummary.fromJson(adminDisputeJson(status: status));
}

AdminDisputeDetail testAdminDisputeDetail({String status = 'open'}) {
  return AdminDisputeDetail.fromJson(<String, dynamic>{
    'dispute': adminDisputeJson(status: status),
    'booking': <String, dynamic>{
      'id': '507f1f77bcf86cd799439091',
      'status': 'confirmed',
      'service_name': 'Home Cleaning',
      'start_at': '2026-09-01T03:00:00.000Z',
      'end_at': '2026-09-01T05:00:00.000Z',
      'quoted_total_minor': 8000,
      'currency_code': 'USD',
    },
  });
}

Map<String, dynamic> adminUserJson({
  String id = '507f1f77bcf86cd799439011',
  String role = 'customer',
  String email = 'pat.customer@example.com',
  String accountStatus = 'active',
  String? fullName = 'Pat Customer',
}) {
  return <String, dynamic>{
    'id': id,
    'role': role,
    'email': email,
    'account_status': accountStatus,
    'email_verified': false,
    'created_at': '2026-08-25T12:00:00.000Z',
    'updated_at': '2026-08-25T12:00:00.000Z',
    'full_name': fullName,
  };
}

AdminUserSummary testAdminUserSummary({
  String role = 'customer',
  String accountStatus = 'active',
}) {
  return AdminUserSummary.fromJson(
    adminUserJson(role: role, accountStatus: accountStatus),
  );
}

AdminUserDetail testAdminUserDetail({
  String role = 'customer',
  String accountStatus = 'active',
  bool protectedAdmin = false,
}) {
  return AdminUserDetail.fromJson(<String, dynamic>{
    'user': adminUserJson(
      role: protectedAdmin ? 'admin' : role,
      accountStatus: accountStatus,
      email: protectedAdmin ? 'admin@example.com' : 'pat.customer@example.com',
      fullName: protectedAdmin ? null : 'Pat Customer',
    ),
    'profile': protectedAdmin ? null : customerProfileJson(),
    'protected_admin_account': protectedAdmin,
    'booking_count': 1,
    'payment_count': 0,
    'active_dispute_count': 0,
  });
}

Map<String, dynamic> adminBookingSummaryJson({
  String status = 'confirmed',
  String? paymentStatus,
  String? disputeStatus,
}) {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd799439091',
    'status': status,
    'customer_user_id': '507f1f77bcf86cd799439011',
    'cleaner_user_id': '507f1f77bcf86cd799439081',
    'customer_display_name': 'Pat Customer',
    'cleaner_public_name': 'Ada Cleaner',
    'service_name': 'Home Cleaning',
    'start_at': '2026-09-01T03:00:00.000Z',
    'end_at': '2026-09-01T05:00:00.000Z',
    'quoted_total_minor': 8000,
    'currency_code': 'USD',
    'payment': paymentStatus == null
        ? null
        : <String, dynamic>{
            'id': '507f1f77bcf86cd7994390a1',
            'status': paymentStatus,
            'amount_minor': 8000,
            'currency_code': 'USD',
            'refunded_amount_minor': 0,
          },
    'dispute': disputeStatus == null
        ? null
        : <String, dynamic>{
            'id': '507f1f77bcf86cd7994390d1',
            'status': disputeStatus,
            'category': 'service_quality',
          },
  };
}

AdminBookingSummary testAdminBookingSummary({
  String status = 'confirmed',
  String? paymentStatus,
  String? disputeStatus,
}) {
  return AdminBookingSummary.fromJson(
    adminBookingSummaryJson(
      status: status,
      paymentStatus: paymentStatus,
      disputeStatus: disputeStatus,
    ),
  );
}

AdminBookingDetail testAdminBookingDetail({
  String status = 'confirmed',
  String? paymentStatus,
}) {
  final bookingJson =
      Map<String, dynamic>.from(customerBookingJson(status: status))
        ..addAll(<String, dynamic>{
          'customer_user_id': '507f1f77bcf86cd799439011',
          'cleaner_user_id': '507f1f77bcf86cd799439081',
          'customer_display_name': 'Pat Customer',
          'cleaner_public_name': 'Ada Cleaner',
          'service_id': '507f1f77bcf86cd799439041',
        });
  bookingJson.remove('cleaner_full_name');
  return AdminBookingDetail.fromJson(<String, dynamic>{
    'booking': bookingJson,
    'payments': paymentStatus == null
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '507f1f77bcf86cd7994390a1',
              'status': paymentStatus,
              'amount_minor': 8000,
              'currency_code': 'USD',
              'refunded_amount_minor': 0,
            },
          ],
    'dispute': null,
  });
}

Map<String, dynamic> adminAuditJson({
  String action = 'user_suspended',
  String targetType = 'user',
}) {
  return <String, dynamic>{
    'id': '507f1f77bcf86cd7994390f1',
    'actor_user_id': '507f1f77bcf86cd799439099',
    'actor_role': 'admin',
    'action': action,
    'target_type': targetType,
    'target_id': '507f1f77bcf86cd799439011',
    'reason': 'Repeated no-show complaints',
    'metadata': <String, Object?>{
      'previous_status': 'active',
      'new_status': 'suspended',
    },
    'created_at': '2026-08-25T12:00:00.000Z',
  };
}

AdminAuditLogSummary testAdminAuditLog({String action = 'user_suspended'}) {
  return AdminAuditLogSummary.fromJson(adminAuditJson(action: action));
}
