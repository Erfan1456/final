import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';

/// Centralized account-action token lifetimes.
abstract final class AccountActionPolicy {
  /// Email verification tokens expire after 24 hours.
  static const Duration emailVerificationLifetime = Duration(hours: 24);

  /// Password reset tokens expire after 30 minutes.
  static const Duration passwordResetLifetime = Duration(minutes: 30);

  /// Opaque token entropy in bytes (256 bits).
  static const int tokenLengthBytes = 32;

  /// Maximum active sessions returned by list.
  static const int maxListedSessions = 50;

  /// Lifetime for [purpose].
  static Duration lifetimeFor(AccountActionPurpose purpose) {
    switch (purpose) {
      case AccountActionPurpose.emailVerification:
        return emailVerificationLifetime;
      case AccountActionPurpose.passwordReset:
        return passwordResetLifetime;
    }
  }
}
