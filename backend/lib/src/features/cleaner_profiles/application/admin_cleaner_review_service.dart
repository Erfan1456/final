import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// One admin list row combining a cleaner profile and a safe user email.
class AdminCleanerApplicationSummary {
  /// Creates a list item.
  const AdminCleanerApplicationSummary({
    required this.profile,
    required this.email,
  });

  /// Cleaner onboarding profile.
  final CleanerProfile profile;

  /// Safe display email from the users collection.
  final String email;

  /// Safe public JSON for admin listing.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': profile.id.oid,
      'user_id': profile.userId.oid,
      'full_name': profile.fullName,
      'email': email,
      'onboarding_status': profile.onboardingStatus.wireValue,
      'submitted_at': profile.submittedAt?.toUtc().toIso8601String(),
    };
  }
}

/// Admin list page.
class AdminCleanerApplicationPage {
  /// Creates a page.
  const AdminCleanerApplicationPage({
    required this.items,
    required this.nextCursor,
  });

  /// Page items.
  final List<AdminCleanerApplicationSummary> items;

  /// Next `_id` cursor, or `null`.
  final String? nextCursor;
}

/// Admin detail combining safe user account fields and the cleaner profile.
class AdminCleanerApplicationDetail {
  /// Creates a detail payload.
  const AdminCleanerApplicationDetail({
    required this.user,
    required this.profile,
  });

  /// Persisted user. Callers must use [authUserJson], never implicit toJson.
  final UserAccount user;

  /// Cleaner onboarding profile.
  final CleanerProfile profile;

  /// Safe public JSON. Omits password hash and session data.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'user': authUserJson(user),
      'profile': profile.toPublicJson(),
    };
  }
}

/// HTTP-independent administrator cleaner-review use cases.
class AdminCleanerReviewService {
  /// Creates a service over [profiles] and [users].
  AdminCleanerReviewService({
    required CleanerProfileRepository profiles,
    required UserRepository users,
  }) : _profiles = profiles,
       _users = users;

  final CleanerProfileRepository _profiles;
  final UserRepository _users;

  /// Lists applications for [status], defaulting to pending.
  Future<AdminCleanerApplicationPage> listApplications({
    required Object? status,
    required Object? limit,
    required Object? after,
  }) async {
    final parsedStatus = _parseStatus(status);
    final parsedLimit = _parseLimit(limit);
    final parsedAfter = _parseAfter(after);
    final page = await _profiles.listByStatusPage(
      status: parsedStatus,
      limit: parsedLimit,
      after: parsedAfter,
    );
    final users = await _users.findByIds(
      page.items.map((profile) => profile.userId),
    );
    final emails = <String, String>{
      for (final user in users) user.id.oid: user.email,
    };
    return AdminCleanerApplicationPage(
      items: [
        for (final profile in page.items)
          if (emails.containsKey(profile.userId.oid))
            AdminCleanerApplicationSummary(
              profile: profile,
              email: emails[profile.userId.oid]!,
            ),
      ],
      nextCursor: page.nextCursor,
    );
  }

  /// Returns one application by cleaner [userId].
  Future<AdminCleanerApplicationDetail> getApplication(ObjectId userId) async {
    final user = await _users.findById(userId);
    final profile = await _profiles.findByUserId(userId);
    if (user == null || profile == null) {
      throw const CleanerApplicationNotFoundException();
    }
    return AdminCleanerApplicationDetail(user: user, profile: profile);
  }

  /// Approves a pending cleaner application.
  Future<CleanerProfile> approve({
    required ObjectId targetUserId,
    required ObjectId adminUserId,
  }) async {
    final approved = await _profiles.approvePendingAtomically(
      userId: targetUserId,
      reviewedBy: adminUserId,
    );
    if (approved != null) {
      return approved;
    }
    final existing = await _profiles.findByUserId(targetUserId);
    if (existing == null) {
      throw const CleanerApplicationNotFoundException();
    }
    throw const InvalidOnboardingStateException();
  }

  /// Rejects a pending cleaner application.
  Future<CleanerProfile> reject({
    required ObjectId targetUserId,
    required ObjectId adminUserId,
    required Object? reason,
  }) async {
    final parsedReason = CleanerProfileValidation.requireRejectionReason(
      reason,
    );
    final rejected = await _profiles.rejectPendingAtomically(
      userId: targetUserId,
      reviewedBy: adminUserId,
      reason: parsedReason,
    );
    if (rejected != null) {
      return rejected;
    }
    final existing = await _profiles.findByUserId(targetUserId);
    if (existing == null) {
      throw const CleanerApplicationNotFoundException();
    }
    throw const InvalidOnboardingStateException();
  }

  CleanerOnboardingStatus _parseStatus(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return CleanerOnboardingStatus.pending;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'Status filter is invalid.',
      );
    }
    try {
      return CleanerOnboardingStatus.fromWire(raw.trim());
    } on FormatException {
      throw const ProfileValidationException(
        message: 'Status filter is invalid.',
      );
    }
  }

  int _parseLimit(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return 20;
    }
    final parsed = switch (raw) {
      final int value => value,
      final String value => int.tryParse(value.trim()),
      _ => null,
    };
    if (parsed == null || parsed < 1 || parsed > 50) {
      throw const ProfileValidationException(
        message: 'Limit must be between 1 and 50.',
      );
    }
    return parsed;
  }

  ObjectId? _parseAfter(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(message: 'Cursor is invalid.');
    }
    try {
      return ObjectId.fromHexString(raw.trim());
    } catch (_) {
      throw const ProfileValidationException(message: 'Cursor is invalid.');
    }
  }
}
