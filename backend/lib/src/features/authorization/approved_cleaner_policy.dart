import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Reusable approved-cleaner check for service and availability management.
///
/// Role middleware still allows unapproved cleaners to use onboarding routes.
class ApprovedCleanerPolicy {
  /// Creates a policy over [profiles].
  ApprovedCleanerPolicy({required CleanerProfileRepository profiles})
    : _profiles = profiles;

  final CleanerProfileRepository _profiles;

  /// Returns the approved profile for [user].
  ///
  /// Throws [CleanerNotApprovedException] when the cleaner is not approved.
  Future<CleanerProfile> requireApproved(UserAccount user) async {
    if (user.role != UserRole.cleaner ||
        user.accountStatus != AccountStatus.active) {
      throw const CleanerNotApprovedException();
    }
    final profile = await _profiles.findByUserId(user.id);
    if (profile == null ||
        profile.onboardingStatus != CleanerOnboardingStatus.approved) {
      throw const CleanerNotApprovedException();
    }
    return profile;
  }

  /// Whether [user] and [profile] may appear in customer discovery.
  static bool isDiscoverable({
    required UserAccount user,
    required CleanerProfile profile,
  }) {
    return user.role == UserRole.cleaner &&
        user.accountStatus == AccountStatus.active &&
        profile.onboardingStatus == CleanerOnboardingStatus.approved &&
        profile.userId == user.id;
  }

  /// Resolves [userId] for callers that already authenticated as a cleaner.
  Future<CleanerProfile> requireApprovedUserId(ObjectId userId) async {
    final profile = await _profiles.findByUserId(userId);
    if (profile == null ||
        profile.onboardingStatus != CleanerOnboardingStatus.approved) {
      throw const CleanerNotApprovedException();
    }
    return profile;
  }
}
