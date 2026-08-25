import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

/// Admin list row for a cleaner application.
class AdminCleanerApplicationSummary {
  /// Creates a summary.
  const AdminCleanerApplicationSummary({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.onboardingStatus,
    this.submittedAt,
  });

  /// Parses a safe list-item JSON object.
  factory AdminCleanerApplicationSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['user_id'];
    final fullName = json['full_name'];
    final email = json['email'];
    final status = json['onboarding_status'];
    final submittedAt = json['submitted_at'];
    if (id is! String ||
        userId is! String ||
        fullName is! String ||
        email is! String ||
        status is! String) {
      throw const FormatException(
        'Cleaner application summary JSON is invalid.',
      );
    }
    return AdminCleanerApplicationSummary(
      id: id,
      userId: userId,
      fullName: fullName,
      email: email,
      onboardingStatus: OnboardingStatus.fromWire(status),
      submittedAt: submittedAt is String
          ? DateTime.parse(submittedAt).toUtc()
          : null,
    );
  }

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final OnboardingStatus onboardingStatus;
  final DateTime? submittedAt;

  @override
  String toString() =>
      'AdminCleanerApplicationSummary(userId: $userId, email: $email)';
}

/// Paginated admin cleaner list.
class AdminCleanerApplicationPage {
  /// Creates a page.
  const AdminCleanerApplicationPage({
    required this.items,
    required this.nextCursor,
  });

  /// Parses a list payload.
  factory AdminCleanerApplicationPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final nextCursor = json['next_cursor'];
    if (items is! List) {
      throw const FormatException('Cleaner application page JSON is invalid.');
    }
    return AdminCleanerApplicationPage(
      items: [
        for (final item in items)
          if (item is Map)
            AdminCleanerApplicationSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ],
      nextCursor: nextCursor is String ? nextCursor : null,
    );
  }

  final List<AdminCleanerApplicationSummary> items;
  final String? nextCursor;
}

/// Admin detail combining a safe user object and cleaner profile.
class AdminCleanerApplicationDetail {
  /// Creates a detail payload.
  const AdminCleanerApplicationDetail({
    required this.userId,
    required this.email,
    required this.profile,
  });

  /// Parses `{ user, profile }`.
  factory AdminCleanerApplicationDetail.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final profile = json['profile'];
    if (user is! Map || profile is! Map) {
      throw const FormatException(
        'Cleaner application detail JSON is invalid.',
      );
    }
    final userMap = Map<String, dynamic>.from(user);
    final email = userMap['email'];
    final userId = userMap['id'];
    if (email is! String || userId is! String) {
      throw const FormatException(
        'Cleaner application detail JSON is invalid.',
      );
    }
    return AdminCleanerApplicationDetail(
      userId: userId,
      email: email,
      profile: CleanerProfile.fromJson(Map<String, dynamic>.from(profile)),
    );
  }

  final String userId;
  final String email;
  final CleanerProfile profile;

  @override
  String toString() => 'AdminCleanerApplicationDetail(userId: $userId)';
}
