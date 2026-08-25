import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';

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
  ];
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
