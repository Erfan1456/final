/// Purpose of a one-time account-action token.
enum AccountActionPurpose {
  /// Confirm a newly registered email address.
  emailVerification,

  /// Replace a forgotten password.
  passwordReset;

  /// Stable database/wire representation.
  String get wireValue {
    switch (this) {
      case AccountActionPurpose.emailVerification:
        return 'email_verification';
      case AccountActionPurpose.passwordReset:
        return 'password_reset';
    }
  }

  /// Parses a stored purpose string.
  static AccountActionPurpose fromWire(String value) {
    switch (value) {
      case 'email_verification':
        return AccountActionPurpose.emailVerification;
      case 'password_reset':
        return AccountActionPurpose.passwordReset;
      default:
        throw const FormatException('Unknown AccountActionPurpose.');
    }
  }
}
