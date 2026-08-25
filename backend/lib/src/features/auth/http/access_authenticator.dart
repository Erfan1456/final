import 'package:home_cleaning_marketplace_api/src/features/auth/http/authenticated_principal.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_service.dart';

/// Bearer access-token verification for protected HTTP requests.
///
/// Reads the Authorization header, requires the Bearer scheme, and verifies
/// the token through [AccessTokenService]. Does not decode JWTs itself.
class AccessAuthenticator {
  /// Creates an authenticator over [tokens].
  const AccessAuthenticator({required AccessTokenService tokens})
    : _tokens = tokens;

  final AccessTokenService _tokens;

  /// Verifies [authorizationHeader] and returns a trusted principal.
  ///
  /// Missing, blank, wrong-scheme, and invalid tokens throw
  /// [InvalidAccessTokenException]. Configuration failures from the token
  /// service propagate as [AccessTokenConfigurationException].
  AuthenticatedPrincipal authenticate(String? authorizationHeader) {
    final token = extractBearerToken(authorizationHeader);
    final claims = _tokens.verify(token);
    return AuthenticatedPrincipal.fromClaims(claims);
  }

  /// Extracts a non-empty Bearer token from [authorizationHeader].
  ///
  /// The scheme comparison is case-insensitive. Parser details are not
  /// included in thrown exceptions.
  static String extractBearerToken(String? authorizationHeader) {
    if (authorizationHeader == null) {
      throw const InvalidAccessTokenException();
    }
    final trimmed = authorizationHeader.trim();
    if (trimmed.isEmpty) {
      throw const InvalidAccessTokenException();
    }

    final match = RegExp(
      r'^Bearer\s+(\S+)\s*$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) {
      throw const InvalidAccessTokenException();
    }

    final token = match.group(1);
    if (token == null || token.isEmpty) {
      throw const InvalidAccessTokenException();
    }
    return token;
  }
}
