/// Cleaner onboarding lifecycle. Wire values are explicit lowercase strings.
enum CleanerOnboardingStatus {
  /// Profile exists and may be edited by the cleaner.
  draft,

  /// Submitted and waiting for administrator review.
  pending,

  /// Administrator approved. Cleaner editing is locked.
  approved,

  /// Administrator rejected. Cleaner may edit and resubmit.
  rejected;

  /// Stable database/wire representation. Never persist [index].
  String get wireValue {
    switch (this) {
      case CleanerOnboardingStatus.draft:
        return 'draft';
      case CleanerOnboardingStatus.pending:
        return 'pending';
      case CleanerOnboardingStatus.approved:
        return 'approved';
      case CleanerOnboardingStatus.rejected:
        return 'rejected';
    }
  }

  /// Whether the cleaner may edit profile fields in this status.
  bool get isEditable =>
      this == CleanerOnboardingStatus.draft ||
      this == CleanerOnboardingStatus.rejected;

  /// Whether the cleaner may submit for review.
  bool get canSubmit => isEditable;

  /// Parses a stored status string. Unknown values fail.
  static CleanerOnboardingStatus fromWire(String value) {
    switch (value) {
      case 'draft':
        return CleanerOnboardingStatus.draft;
      case 'pending':
        return CleanerOnboardingStatus.pending;
      case 'approved':
        return CleanerOnboardingStatus.approved;
      case 'rejected':
        return CleanerOnboardingStatus.rejected;
      default:
        throw const FormatException('Unknown CleanerOnboardingStatus.');
    }
  }
}
