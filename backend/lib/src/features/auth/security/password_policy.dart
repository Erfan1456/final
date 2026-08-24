/// Outcome of [PasswordPolicy.validate].
enum PasswordPolicyIssue {
  /// Fewer than [PasswordPolicy.minimumLength] Unicode code points.
  tooShort,

  /// More than [PasswordPolicy.maximumLength] Unicode code points.
  tooLong,
}

/// Explicit valid/invalid result. Does not hash or estimate entropy.
class PasswordValidationResult {
  /// Creates a valid result.
  const PasswordValidationResult.valid() : issue = null;

  /// Creates an invalid result with a single [issue].
  const PasswordValidationResult.invalid(this.issue);

  /// `null` when the password is valid.
  final PasswordPolicyIssue? issue;

  /// Whether the password satisfies the policy.
  bool get isValid => issue == null;
}

/// Server-side password policy for future public account creation.
///
/// Passwords are opaque secrets. This policy does not trim, case-fold, or
/// Unicode-normalize the value.
class PasswordPolicy {
  /// Creates a policy using the approved length bounds.
  const PasswordPolicy();

  /// Minimum Unicode code points (runes).
  static const int minimumLength = 15;

  /// Maximum Unicode code points (runes).
  static const int maximumLength = 128;

  /// Validates [password] without modifying it.
  PasswordValidationResult validate(String password) {
    final length = password.runes.length;
    if (length < minimumLength) {
      return const PasswordValidationResult.invalid(
        PasswordPolicyIssue.tooShort,
      );
    }
    if (length > maximumLength) {
      return const PasswordValidationResult.invalid(
        PasswordPolicyIssue.tooLong,
      );
    }
    return const PasswordValidationResult.valid();
  }
}
