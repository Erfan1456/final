import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_field_validation.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent cleaner onboarding use cases.
class CleanerOnboardingService {
  /// Creates a service over [profiles].
  CleanerOnboardingService({required CleanerProfileRepository profiles})
    : _profiles = profiles;

  final CleanerProfileRepository _profiles;

  /// Returns the cleaner profile for [userId], or `null`.
  Future<CleanerProfile?> getProfile(ObjectId userId) {
    return _profiles.findByUserId(userId);
  }

  /// Creates a draft or updates an editable (draft/rejected) profile.
  Future<CleanerProfile> saveProfile({
    required ObjectId userId,
    required Object? fullName,
    required Object? phoneE164,
    required Object? bio,
    required Object? yearsExperience,
    required Object? serviceArea,
  }) async {
    final data = CleanerProfileWriteData(
      fullName: ProfileFieldValidation.requireFullName(fullName),
      phoneE164: ProfileFieldValidation.optionalPhoneE164(phoneE164),
      bio: CleanerProfileValidation.requireBio(bio),
      yearsExperience: CleanerProfileValidation.requireYearsExperience(
        yearsExperience,
      ),
      serviceArea: CleanerProfileValidation.requireServiceArea(serviceArea),
    );

    final existing = await _profiles.findByUserId(userId);
    if (existing == null) {
      try {
        return await _profiles.createDraft(userId: userId, data: data);
      } on DuplicateCleanerProfileException {
        final raced = await _profiles.updateEditableAtomically(
          userId: userId,
          data: data,
        );
        if (raced == null) {
          throw const CleanerProfileLockedException();
        }
        return raced;
      }
    }
    if (!existing.onboardingStatus.isEditable) {
      throw const CleanerProfileLockedException();
    }
    final updated = await _profiles.updateEditableAtomically(
      userId: userId,
      data: data,
    );
    if (updated == null) {
      throw const CleanerProfileLockedException();
    }
    return updated;
  }

  /// Submits a draft or rejected profile for administrator review.
  Future<CleanerProfile> submit(ObjectId userId) async {
    final submitted = await _profiles.submitAtomically(userId);
    if (submitted != null) {
      return submitted;
    }
    final existing = await _profiles.findByUserId(userId);
    if (existing == null) {
      throw const CleanerProfileRequiredException();
    }
    throw const InvalidOnboardingStateException();
  }
}
