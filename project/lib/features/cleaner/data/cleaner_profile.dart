/// Cleaner onboarding lifecycle. Unknown server values are [unknown].
enum OnboardingStatus {
  draft,
  pending,
  approved,
  rejected,
  unknown;

  /// Parses a lowercase wire value without crashing on unknowns.
  static OnboardingStatus fromWire(String value) {
    switch (value) {
      case 'draft':
        return OnboardingStatus.draft;
      case 'pending':
        return OnboardingStatus.pending;
      case 'approved':
        return OnboardingStatus.approved;
      case 'rejected':
        return OnboardingStatus.rejected;
      default:
        return OnboardingStatus.unknown;
    }
  }

  /// Whether the cleaner may edit the profile.
  bool get isEditable =>
      this == OnboardingStatus.draft || this == OnboardingStatus.rejected;

  /// Stable lowercase wire value for known statuses.
  String get wireValue {
    switch (this) {
      case OnboardingStatus.draft:
        return 'draft';
      case OnboardingStatus.pending:
        return 'pending';
      case OnboardingStatus.approved:
        return 'approved';
      case OnboardingStatus.rejected:
        return 'rejected';
      case OnboardingStatus.unknown:
        return 'unknown';
    }
  }
}

/// Safe cleaner onboarding profile.
class CleanerProfile {
  /// Creates a profile.
  const CleanerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.bio,
    required this.yearsExperience,
    required this.serviceArea,
    required this.onboardingStatus,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  /// Parses a safe cleaner profile JSON object.
  factory CleanerProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['user_id'];
    final fullName = json['full_name'];
    final phone = json['phone_e164'];
    final bio = json['bio'];
    final years = json['years_experience'];
    final serviceArea = json['service_area'];
    final status = json['onboarding_status'];
    final submittedAt = json['submitted_at'];
    final reviewedAt = json['reviewed_at'];
    final reviewedBy = json['reviewed_by'];
    final rejectionReason = json['rejection_reason'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    if (id is! String ||
        userId is! String ||
        fullName is! String ||
        bio is! String ||
        years is! int ||
        serviceArea is! String ||
        status is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException('Cleaner profile JSON is invalid.');
    }
    return CleanerProfile(
      id: id,
      userId: userId,
      fullName: fullName,
      phoneE164: phone is String ? phone : null,
      bio: bio,
      yearsExperience: years,
      serviceArea: serviceArea,
      onboardingStatus: OnboardingStatus.fromWire(status),
      submittedAt: submittedAt is String
          ? DateTime.parse(submittedAt).toUtc()
          : null,
      reviewedAt: reviewedAt is String
          ? DateTime.parse(reviewedAt).toUtc()
          : null,
      reviewedBy: reviewedBy is String ? reviewedBy : null,
      rejectionReason: rejectionReason is String ? rejectionReason : null,
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  final String id;
  final String userId;
  final String fullName;
  final String? phoneE164;
  final String bio;
  final int yearsExperience;
  final String serviceArea;
  final OnboardingStatus onboardingStatus;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  String toString() =>
      'CleanerProfile(id: $id, status: ${onboardingStatus.wireValue})';
}
