import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_result.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';

/// Safe snake_case user object for authentication HTTP responses.
///
/// Equivalently safe to [UserAccount.toPublicJson]: omits password hash,
/// normalized email, and MongoDB internals.
Map<String, Object> authUserJson(UserAccount user) {
  return <String, Object>{
    'id': user.id.oid,
    'role': user.role.wireValue,
    'email': user.email,
    'account_status': user.accountStatus.wireValue,
    'email_verified': user.emailVerified,
    'created_at': user.createdAt.toUtc().toIso8601String(),
    'updated_at': user.updatedAt.toUtc().toIso8601String(),
  };
}

/// Safe token object for authentication HTTP responses.
Map<String, Object> authTokensJson({
  required String accessToken,
  required String refreshToken,
  int expiresInSeconds = 900,
}) {
  return <String, Object>{
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': 'Bearer',
    'expires_in': expiresInSeconds,
  };
}

/// Signup/login success `data` payload.
Map<String, Object> authenticationDataJson(AuthenticationResult result) {
  return <String, Object>{
    'user': authUserJson(result.user),
    'tokens': authTokensJson(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresInSeconds: result.expiresInSeconds,
    ),
  };
}

/// Refresh success `data` payload.
Map<String, Object> refreshedTokensDataJson(RefreshedTokens tokens) {
  return <String, Object>{
    'tokens': authTokensJson(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInSeconds: tokens.expiresInSeconds,
    ),
  };
}
