import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_claims.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Access-token issuance and verification boundary.
///
/// Future routes and middleware must call this instead of dart_jsonwebtoken.
abstract interface class AccessTokenService {
  /// Issues a signed access JWT for [userId], [sessionId], and [role].
  String issue({
    required ObjectId userId,
    required ObjectId sessionId,
    required UserRole role,
  });

  /// Verifies [token] and returns trusted claims.
  ///
  /// Invalid tokens throw [InvalidAccessTokenException].
  AccessTokenClaims verify(String token);
}
