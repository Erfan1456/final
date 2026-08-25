/// Client-side field checks. The backend remains authoritative.
abstract final class AuthValidation {
  static const int loginPasswordMaxRunes = 128;
  static const int signupPasswordMinRunes = 15;
  static const int signupPasswordMaxRunes = 128;
  static const int emailMaxLength = 254;

  /// Trims and checks a basic email shape. Does not lowercase.
  static String? emailError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Enter your email address.';
    }
    if (trimmed.length > emailMaxLength) {
      return 'Enter a valid email address.';
    }
    final separator = trimmed.indexOf('@');
    if (separator <= 0 || separator != trimmed.lastIndexOf('@')) {
      return 'Enter a valid email address.';
    }
    if (trimmed.substring(separator + 1).isEmpty) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Login: non-empty, at most 128 code points. Does not trim.
  static String? loginPasswordError(String password) {
    if (password.isEmpty) {
      return 'Enter your password.';
    }
    if (password.runes.length > loginPasswordMaxRunes) {
      return 'Password is too long.';
    }
    return null;
  }

  /// Signup: 15–128 Unicode code points. Does not trim.
  static String? signupPasswordError(String password) {
    final length = password.runes.length;
    if (length < signupPasswordMinRunes) {
      return 'Password must be at least 15 characters.';
    }
    if (length > signupPasswordMaxRunes) {
      return 'Password is too long.';
    }
    return null;
  }
}
