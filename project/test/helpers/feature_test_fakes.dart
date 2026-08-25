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
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';

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
  );
}

CleanerDiscoveryDetail testDiscoveryDetail({
  String cleanerUserId = '507f1f77bcf86cd799439081',
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
