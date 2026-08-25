import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address.dart';
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

/// Customer service address for booking tests.
Address testAddress({
  required ObjectId userId,
  ObjectId? id,
  String label = 'Home',
  String line1 = '12 Test Street',
  String? line2,
  String city = 'Dhaka',
  String region = 'Dhaka',
  String postalCode = '1205',
  String countryCode = 'BD',
}) {
  final created = DateTime.utc(2026, 8, 20, 12);
  return Address(
    id: id ?? ObjectId.fromHexString('507f1f77bcf86cd7994390a1'),
    userId: userId,
    label: label,
    line1: line1,
    line2: line2,
    city: city,
    region: region,
    postalCode: postalCode,
    countryCode: countryCode,
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

  @override
  Future<UserAccountPage> adminPage({
    required int limit,
    UserRole? role,
    AccountStatus? status,
    String? emailNormalized,
    ObjectId? after,
  }) async {
    var matches = users.toList();
    if (role != null) {
      matches = [
        for (final user in matches)
          if (user.role == role) user,
      ];
    }
    if (status != null) {
      matches = [
        for (final user in matches)
          if (user.accountStatus == status) user,
      ];
    }
    if (emailNormalized != null) {
      matches = [
        for (final user in matches)
          if (user.emailNormalized == emailNormalized) user,
      ];
    }
    matches.sort((a, b) => b.id.oid.compareTo(a.id.oid));
    if (after != null) {
      matches = [
        for (final user in matches)
          if (user.id.oid.compareTo(after.oid) < 0) user,
      ];
    }
    final hasMore = matches.length > limit;
    final page = hasMore ? matches.sublist(0, limit) : matches;
    return UserAccountPage(
      items: page,
      nextCursor: hasMore ? page.last.id.oid : null,
    );
  }

  @override
  Future<UserAccount?> setActiveToSuspended({
    required ObjectId userId,
    required DateTime now,
  }) {
    return _setStatus(
      userId: userId,
      now: now,
      allowedFrom: {AccountStatus.active},
      to: AccountStatus.suspended,
    );
  }

  @override
  Future<UserAccount?> setSuspendedToActive({
    required ObjectId userId,
    required DateTime now,
  }) {
    return _setStatus(
      userId: userId,
      now: now,
      allowedFrom: {AccountStatus.suspended},
      to: AccountStatus.active,
    );
  }

  @override
  Future<UserAccount?> setActiveOrSuspendedToDeactivated({
    required ObjectId userId,
    required DateTime now,
  }) {
    return _setStatus(
      userId: userId,
      now: now,
      allowedFrom: {AccountStatus.active, AccountStatus.suspended},
      to: AccountStatus.deactivated,
    );
  }

  Future<UserAccount?> _setStatus({
    required ObjectId userId,
    required DateTime now,
    required Set<AccountStatus> allowedFrom,
    required AccountStatus to,
  }) async {
    final index = users.indexWhere((user) => user.id == userId);
    if (index < 0) {
      return null;
    }
    final current = users[index];
    if (current.role == UserRole.admin ||
        !allowedFrom.contains(current.accountStatus)) {
      return null;
    }
    final updated = UserAccount(
      id: current.id,
      role: current.role,
      email: current.email,
      emailNormalized: current.emailNormalized,
      passwordHash: current.passwordHash,
      accountStatus: to,
      emailVerified: current.emailVerified,
      createdAt: current.createdAt,
      updatedAt: now.toUtc(),
    );
    users[index] = updated;
    return updated;
  }
}
