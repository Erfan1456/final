import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Input for persisting a new user session.
///
/// Contains an already-produced refresh-token hash. Never contains a raw
/// refresh token. Persistence fields such as `_id` and timestamps are derived
/// by the repository.
class CreateUserSessionData {
  /// Creates session insert input.
  const CreateUserSessionData({
    required this.userId,
    required this.refreshTokenHash,
    required this.expiresAt,
  });

  /// Owning account `_id`.
  final ObjectId userId;

  /// SHA-256 lookup hash of the raw refresh token.
  final String refreshTokenHash;

  /// Absolute UTC session expiration. Rotation must not change this.
  final DateTime expiresAt;
}
