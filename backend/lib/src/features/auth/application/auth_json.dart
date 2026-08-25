import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_delivery_provider.dart';
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

/// Signup pending-verification `data` payload. Never includes tokens.
Map<String, Object> signupDataJson(SignupResult result) {
  final data = <String, Object>{
    'user': authUserJson(result.user),
    'verification_required': result.verificationRequired,
  };
  final action = result.developmentAction;
  if (action != null) {
    data['development_action'] = action.toJson();
  }
  return data;
}

/// Generic account-action request `data` payload.
Map<String, Object> accountActionRequestDataJson({
  required String message,
  DevelopmentAccountAction? developmentAction,
}) {
  final data = <String, Object>{
    'message': message,
  };
  if (developmentAction != null) {
    data['development_action'] = developmentAction.toJson();
  }
  return data;
}

/// Safe listed-session JSON. Never includes refresh-token hashes.
Map<String, Object> accountSessionJson(AccountSessionSummary session) {
  return <String, Object>{
    'id': session.id.oid,
    'created_at': session.createdAt.toUtc().toIso8601String(),
    'expires_at': session.expiresAt.toUtc().toIso8601String(),
    'last_rotated_at': session.lastRotatedAt.toUtc().toIso8601String(),
    'is_current': session.isCurrent,
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
