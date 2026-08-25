/// Stored access/refresh pair. Never logged or printed.
class AuthTokenPair {
  /// Creates a token pair. Values must not be logged.
  const AuthTokenPair({required this.accessToken, required this.refreshToken});

  /// Parses `access_token` and `refresh_token` from a backend tokens object.
  factory AuthTokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const FormatException('Token pair is missing required fields.');
    }
    return AuthTokenPair(accessToken: access, refreshToken: refresh);
  }

  /// Opaque access JWT. Do not decode for identity.
  final String accessToken;

  /// Opaque rotating refresh token.
  final String refreshToken;

  /// JSON object stored in secure storage and sent to the API.
  Map<String, String> toJson() {
    return <String, String>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  @override
  String toString() => 'AuthTokenPair(redacted)';
}
