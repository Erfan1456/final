import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_claims.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';

/// Successful signup or login credentials returned to the application layer.
///
/// Does not include password hashes, refresh-token hashes, or signing secrets.
class AuthenticationResult {
  /// Creates a safe authentication result.
  const AuthenticationResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresInSeconds = 900,
  });

  /// Authenticated account. Serialize with a public/auth DTO, never [UserAccount.toDocument].
  final UserAccount user;

  /// Signed access JWT.
  final String accessToken;

  /// Newly issued raw refresh token.
  final String refreshToken;

  /// Access-token lifetime in seconds.
  final int expiresInSeconds;
}

/// Successful refresh credentials. Does not include user data.
class RefreshedTokens {
  /// Creates a token-only refresh result.
  const RefreshedTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresInSeconds = 900,
  });

  /// Newly issued access JWT.
  final String accessToken;

  /// Newly issued raw refresh token. Never the previous token.
  final String refreshToken;

  /// Access-token lifetime in seconds.
  final int expiresInSeconds;
}

/// Default access-token lifetime used in HTTP `expires_in`.
int get accessTokenExpiresInSeconds => accessTokenLifetime.inSeconds;
