import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:hashlib/random.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_claims.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HS256 access-token service using `ACCESS_TOKEN_SECRET`.
class JwtAccessTokenService implements AccessTokenService {
  /// Creates a service. [secret] must be at least 32 UTF-8 bytes.
  ///
  /// [jwtIdBytes] is a test-only injection seam. Production omits it.
  JwtAccessTokenService({
    required String secret,
    List<int> Function(int length)? jwtIdBytes,
  }) : _secret = secret,
       _jwtIdBytes = jwtIdBytes ?? _secureBytes {
    _ensureSecret(_secret);
  }

  /// Builds from [ServerConfig]. Rejects missing or short secrets.
  factory JwtAccessTokenService.fromConfig(ServerConfig config) {
    return JwtAccessTokenService(secret: config.accessTokenSecret);
  }

  static const String _hs256 = 'HS256';

  final String _secret;
  final List<int> Function(int length) _jwtIdBytes;

  static List<int> _secureBytes(int length) => randomBytes(length);

  static void _ensureSecret(String secret) {
    if (utf8.encode(secret).length < accessTokenSecretMinUtf8Bytes) {
      throw const AccessTokenConfigurationException();
    }
  }

  @override
  String issue({
    required ObjectId userId,
    required ObjectId sessionId,
    required UserRole role,
  }) {
    _ensureSecret(_secret);
    final jwtId = base64Url
        .encode(_jwtIdBytes(accessTokenJwtIdLengthBytes))
        .replaceAll('=', '');
    final jwt = JWT(
      <String, dynamic>{
        'sid': sessionId.oid,
        'role': role.wireValue,
      },
      subject: userId.oid,
      issuer: accessTokenIssuer,
      audience: Audience.one(accessTokenAudience),
      jwtId: jwtId,
    );
    return jwt.sign(
      SecretKey(_secret),
      algorithm: JWTAlgorithm.HS256, // ignore: avoid_redundant_argument_values
      expiresIn: accessTokenLifetime,
    );
  }

  @override
  AccessTokenClaims verify(String token) {
    _ensureSecret(_secret);
    if (_headerAlg(token) != _hs256) {
      throw const InvalidAccessTokenException();
    }

    final JWT jwt;
    try {
      jwt = JWT.verify(
        token,
        SecretKey(_secret),
        issuer: accessTokenIssuer,
        audience: Audience.one(accessTokenAudience),
      );
    } on JWTException {
      throw const InvalidAccessTokenException();
    }

    if (jwt.header?['alg'] != _hs256) {
      throw const InvalidAccessTokenException();
    }

    final payload = jwt.payload;
    if (payload is! Map) {
      throw const InvalidAccessTokenException();
    }

    return AccessTokenClaims.fromVerifiedPayload(
      Map<String, dynamic>.from(payload),
    );
  }

  /// Reads the JOSE `alg` only. Payload claims are not trusted here.
  static String? _headerAlg(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      var padded = parts[0];
      final remainder = padded.length % 4;
      if (remainder != 0) {
        padded = padded.padRight(padded.length + (4 - remainder), '=');
      }
      final decoded = utf8.decode(base64Url.decode(padded));
      final header = jsonDecode(decoded);
      if (header is! Map) {
        return null;
      }
      final alg = header['alg'];
      return alg is String ? alg : null;
    } catch (_) {
      return null;
    }
  }
}
