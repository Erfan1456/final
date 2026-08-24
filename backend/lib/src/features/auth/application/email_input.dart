import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';

/// HTTP email validation for signup and login.
///
/// Trims surrounding whitespace only. Does not lowercase the stored display
/// email, apply Gmail-specific rewriting, or implement RFC 5322.
class EmailInput {
  /// Maximum accepted length after trim, in UTF-16 code units.
  static const int maxLength = 254;

  /// Returns the trimmed email or throws [InvalidAuthInputException].
  static String parse(String value) {
    final trimmed = value.trim();
    if (!_isAcceptable(trimmed)) {
      throw const InvalidAuthInputException(
        code: 'invalid_email',
        message: 'Enter a valid email address.',
      );
    }
    return trimmed;
  }

  static bool _isAcceptable(String trimmed) {
    if (trimmed.isEmpty || trimmed.length > maxLength) {
      return false;
    }
    for (final unit in trimmed.codeUnits) {
      if (unit <= 0x20 || unit == 0x7F) {
        return false;
      }
    }
    final separator = trimmed.indexOf('@');
    if (separator <= 0 || separator != trimmed.lastIndexOf('@')) {
      return false;
    }
    return trimmed.substring(separator + 1).isNotEmpty;
  }
}
