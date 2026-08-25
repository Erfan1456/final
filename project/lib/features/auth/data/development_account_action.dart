/// Development/test-only account-action payload from the API.
///
/// Never persist or log [token].
class DevelopmentAccountAction {
  /// Creates a development action result.
  const DevelopmentAccountAction({
    required this.purpose,
    required this.token,
  });

  /// Parses the safe development envelope. Unknown fields are ignored.
  factory DevelopmentAccountAction.fromJson(Map<String, dynamic> json) {
    final purpose = json['purpose'];
    final token = json['token'];
    if (purpose is! String ||
        purpose.isEmpty ||
        token is! String ||
        token.isEmpty) {
      throw const FormatException(
        'Development account action JSON is missing required fields.',
      );
    }
    return DevelopmentAccountAction(purpose: purpose, token: token);
  }

  /// Token purpose wire value, e.g. `email_verification`.
  final String purpose;

  /// Raw one-time token. Shown only in development/test responses.
  final String token;
}
