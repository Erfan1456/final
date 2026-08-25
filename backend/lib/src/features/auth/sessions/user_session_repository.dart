import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/create_user_session_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for refresh sessions.
abstract class UserSessionRepository {
  /// Inserts a new logical session.
  Future<UserSession> create(CreateUserSessionData data);

  /// Returns the session with MongoDB `_id` equal to [id], or `null`.
  Future<UserSession?> findById(ObjectId id);

  /// Returns the session whose current refresh-token hash matches [hash].
  Future<UserSession?> findByCurrentRefreshTokenHash(String hash);

  /// Returns a session that previously consumed [hash], or `null`.
  Future<UserSession?> findByUsedRefreshTokenHash(String hash);

  /// Atomically replaces the current refresh-token hash when it still matches.
  ///
  /// Matches `refresh_token_hash == currentRefreshTokenHash`, `revoked_at ==
  /// null`, and `expires_at > now`. Returns the updated session, or `null` if
  /// nothing matched.
  Future<UserSession?> rotateCurrentTokenAtomically({
    required String currentRefreshTokenHash,
    required String newRefreshTokenHash,
    required DateTime now,
  });

  /// Sets `revoked_at` on [id] if it is not already revoked.
  Future<UserSession?> revokeById(ObjectId id, {required DateTime now});

  /// Sets `revoked_at` on all non-revoked sessions for [userId].
  Future<int> revokeAllForUser(ObjectId userId, {required DateTime now});

  /// Returns active (non-revoked, unexpired) sessions for [userId].
  Future<List<UserSession>> findActiveForUser({
    required ObjectId userId,
    required DateTime now,
    required int limit,
  });
}
