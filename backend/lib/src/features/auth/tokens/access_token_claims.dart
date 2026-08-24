import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// JWT issuer for access tokens.
const String accessTokenIssuer = 'home_cleaning_marketplace_api';

/// JWT audience for access tokens.
const String accessTokenAudience = 'home_cleaning_marketplace';

/// Access-token lifetime.
const Duration accessTokenLifetime = Duration(minutes: 15);

/// Minimum ACCESS_TOKEN_SECRET length in UTF-8 bytes.
const int accessTokenSecretMinUtf8Bytes = 32;

/// JWT identifier entropy in bytes.
const int accessTokenJwtIdLengthBytes = 16;

/// Verified access-token claims used for future authorization.
class AccessTokenClaims {
  /// Creates claims from a successfully verified token.
  const AccessTokenClaims({
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.jwtId,
    required this.issuedAt,
    required this.expiresAt,
  });

  /// Parses required claims from a verified JWT payload.
  ///
  /// Unknown roles and malformed ObjectIds fail. Do not call this on an
  /// unverified decoded JWT payload.
  factory AccessTokenClaims.fromVerifiedPayload(Map<String, dynamic> payload) {
    final subject = _requireString(payload, 'sub');
    final sessionId = _requireString(payload, 'sid');
    final roleWire = _requireString(payload, 'role');
    final jwtId = _requireString(payload, 'jti');
    final issuedAt = _requireUtcSeconds(payload, 'iat');
    final expiresAt = _requireUtcSeconds(payload, 'exp');

    final UserRole role;
    try {
      role = UserRole.fromWire(roleWire);
    } on FormatException {
      throw const InvalidAccessTokenException();
    }

    return AccessTokenClaims(
      userId: _requireObjectId(subject),
      sessionId: _requireObjectId(sessionId),
      role: role,
      jwtId: jwtId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }

  /// Account `_id` from `sub`.
  final ObjectId userId;

  /// Session `_id` from `sid`.
  final ObjectId sessionId;

  /// Explicit `UserRole` wire value.
  final UserRole role;

  /// Unique JWT identifier (`jti`).
  final String jwtId;

  /// UTC issuance time (`iat`).
  final DateTime issuedAt;

  /// UTC expiration (`exp`).
  final DateTime expiresAt;

  static String _requireString(Map<String, dynamic> payload, String claim) {
    final value = payload[claim];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw const InvalidAccessTokenException();
  }

  static DateTime _requireUtcSeconds(
    Map<String, dynamic> payload,
    String claim,
  ) {
    final value = payload[claim];
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).toInt(),
        isUtc: true,
      );
    }
    throw const InvalidAccessTokenException();
  }

  static ObjectId _requireObjectId(String value) {
    try {
      return ObjectId.fromHexString(value);
    } catch (error) {
      if (error is FormatException || error is ArgumentError) {
        throw const InvalidAccessTokenException();
      }
      rethrow;
    }
  }
}
