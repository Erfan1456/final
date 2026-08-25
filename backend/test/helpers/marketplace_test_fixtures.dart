import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/application/canonical_service_catalog.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Fixed clock used by availability tests.
DateTime marketplaceTestNow() => DateTime.utc(2026, 8, 25, 12);

/// Canonical home-cleaning document for tests.
MarketplaceService testHomeCleaningService({
  bool active = true,
  ObjectId? id,
}) {
  final created = DateTime.utc(2026, 8, 20, 12);
  return MarketplaceService(
    id: id ?? ObjectId.fromHexString('507f1f77bcf86cd7994390aa'),
    slug: CanonicalHomeCleaningService.slug,
    name: CanonicalHomeCleaningService.name,
    description: CanonicalHomeCleaningService.description,
    billingModel: CanonicalHomeCleaningService.billingModel,
    active: active,
    createdAt: created,
    updatedAt: created,
  );
}

UserAccount testUserAccount({
  ObjectId? id,
  UserRole role = UserRole.cleaner,
  AccountStatus status = AccountStatus.active,
  String email = 'cleaner@example.com',
}) {
  final created = DateTime.utc(2026, 8, 20, 12);
  final userId = id ?? ObjectId.fromHexString('507f1f77bcf86cd799439011');
  return UserAccount(
    id: userId,
    role: role,
    email: email,
    emailNormalized: email.toLowerCase(),
    passwordHash: 'hashed-password-must-not-appear',
    accountStatus: status,
    emailVerified: false,
    createdAt: created,
    updatedAt: created,
  );
}

CleanerProfile testCleanerProfileRecord({
  required ObjectId userId,
  CleanerOnboardingStatus status = CleanerOnboardingStatus.approved,
  int yearsExperience = 3,
  String fullName = 'Test Cleaner',
  String bio = 'Experienced residential cleaner for apartments.',
  ObjectId? id,
}) {
  final created = DateTime.utc(2026, 8, 20, 12);
  return CleanerProfile(
    id: id ?? ObjectId(),
    userId: userId,
    fullName: fullName,
    phoneE164: '+15555550101',
    bio: bio,
    yearsExperience: yearsExperience,
    serviceArea: 'Dhaka North',
    onboardingStatus: status,
    createdAt: created,
    updatedAt: created,
  );
}

/// In-memory [UserRepository] with invocation counting. Atlas-free.
class MemoryUserRepository implements UserRepository {
  final List<UserAccount> users = <UserAccount>[];
  int findByIdsCalls = 0;
  int findByIdCalls = 0;

  @override
  Future<UserAccount?> findById(ObjectId id) async {
    findByIdCalls += 1;
    for (final user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<UserAccount?> findByEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<bool> emailExists(String email) {
    throw UnimplementedError();
  }

  @override
  Future<List<UserAccount>> findByIds(Iterable<ObjectId> ids) async {
    findByIdsCalls += 1;
    final wanted = ids.map((id) => id.oid).toSet();
    return [
      for (final user in users)
        if (wanted.contains(user.id.oid)) user,
    ];
  }

  @override
  Future<UserAccount> create(CreateUserAccountData data) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePasswordHash({
    required ObjectId userId,
    required String passwordHash,
    required DateTime updatedAt,
  }) {
    throw UnimplementedError();
  }
}
