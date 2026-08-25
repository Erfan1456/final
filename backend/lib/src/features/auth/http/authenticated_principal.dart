import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_claims.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Verified access-token identity for protected routes.
///
/// Created only after access-token verification succeeds. Does not include
/// email, password, refresh tokens, or token hashes.
class AuthenticatedPrincipal {
  /// Creates a principal from trusted claims.
  const AuthenticatedPrincipal({
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.jwtId,
  });

  /// Builds a principal from verified [claims].
  factory AuthenticatedPrincipal.fromClaims(AccessTokenClaims claims) {
    return AuthenticatedPrincipal(
      userId: claims.userId,
      sessionId: claims.sessionId,
      role: claims.role,
      jwtId: claims.jwtId,
    );
  }

  /// Account `_id` from the access-token subject.
  final ObjectId userId;

  /// Refresh-session `_id` from the `sid` claim.
  final ObjectId sessionId;

  /// Role encoded in the verified access token.
  final UserRole role;

  /// JWT identifier (`jti`).
  final String jwtId;

  @override
  String toString() =>
      'AuthenticatedPrincipal(userId: ${userId.oid}, '
      'sessionId: ${sessionId.oid}, role: ${role.wireValue})';
}
