import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/create_user_session_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/refresh_token.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Absolute refresh-session lifetime. Rotation does not extend this.
const Duration refreshSessionLifetime = Duration(days: 30);

/// Result of creating or rotating a refresh session.
class IssuedRefreshSession {
  /// Creates a result. [rawRefreshToken] is returned only to the caller.
  const IssuedRefreshSession({
    required this.session,
    required this.rawRefreshToken,
  });

  /// Persisted session. Token hashes stay on the session object for
  /// persistence tests; they must not be returned over HTTP later.
  final UserSession session;

  /// Opaque raw refresh token. Never persist this value.
  final String rawRefreshToken;
}

/// Refresh-session lifecycle: create, rotate, revoke.
///
/// Does not depend on Dart Frog request objects.
class AuthSessionService {
  /// Creates a service over [sessions].
  AuthSessionService({
    required UserSessionRepository sessions,
    RefreshTokenGenerator? refreshTokenGenerator,
    RefreshTokenHasher? refreshTokenHasher,
    DateTime Function()? clock,
  }) : _sessions = sessions,
       _generator = refreshTokenGenerator ?? RefreshTokenGenerator(),
       _hasher = refreshTokenHasher ?? const RefreshTokenHasher(),
       _clock = clock ?? _utcNow;

  final UserSessionRepository _sessions;
  final RefreshTokenGenerator _generator;
  final RefreshTokenHasher _hasher;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  /// Creates a logical session and returns the raw refresh token to the caller.
  ///
  /// The repository receives only the SHA-256 hash.
  Future<IssuedRefreshSession> createSession(ObjectId userId) async {
    final now = _clock().toUtc();
    final raw = _generator.generate();
    final session = await _sessions.create(
      CreateUserSessionData(
        userId: userId,
        refreshTokenHash: _hasher.hashToken(raw),
        expiresAt: now.add(refreshSessionLifetime),
      ),
    );
    return IssuedRefreshSession(session: session, rawRefreshToken: raw);
  }

  /// Rotates the current refresh token atomically.
  ///
  /// Does not extend [UserSession.expiresAt]. Replay of a consumed token
  /// revokes the logical session.
  Future<IssuedRefreshSession> rotateRefreshToken(
    String rawRefreshToken,
  ) async {
    final now = _clock().toUtc();
    final presentedHash = _hasher.hashToken(rawRefreshToken);
    final newRaw = _generator.generate();
    final newHash = _hasher.hashToken(newRaw);

    final rotated = await _sessions.rotateCurrentTokenAtomically(
      currentRefreshTokenHash: presentedHash,
      newRefreshTokenHash: newHash,
      now: now,
    );
    if (rotated != null) {
      return IssuedRefreshSession(
        session: rotated,
        rawRefreshToken: newRaw,
      );
    }

    final reused = await _sessions.findByUsedRefreshTokenHash(presentedHash);
    if (reused != null) {
      await _sessions.revokeById(reused.id, now: now);
      throw const RefreshTokenReuseDetectedException();
    }

    throw const InvalidRefreshTokenException();
  }

  /// Revokes the logical session [sessionId] without inspecting a raw token.
  Future<void> revokeById(ObjectId sessionId) async {
    await _sessions.revokeById(sessionId, now: _clock().toUtc());
  }

  /// Revokes the logical session identified by the presented refresh token.
  Future<void> revokeSession(String rawRefreshToken) async {
    final now = _clock().toUtc();
    final hash = _hasher.hashToken(rawRefreshToken);
    final current = await _sessions.findByCurrentRefreshTokenHash(hash);
    final session = current ?? await _sessions.findByUsedRefreshTokenHash(hash);
    if (session == null) {
      throw const InvalidRefreshTokenException();
    }
    await _sessions.revokeById(session.id, now: now);
  }

  /// Revokes every non-revoked session for [userId].
  Future<int> revokeAllForUser(ObjectId userId) {
    return _sessions.revokeAllForUser(userId, now: _clock().toUtc());
  }

  /// Lists active sessions for [userId], newest first, capped at 50.
  Future<List<UserSession>> listActiveForUser(ObjectId userId) {
    return _sessions.findActiveForUser(
      userId: userId,
      now: _clock().toUtc(),
      limit: AccountActionPolicy.maxListedSessions,
    );
  }

  /// Revokes [sessionId] when it belongs to [userId].
  ///
  /// Returns the session when owned (including already-revoked). Returns
  /// `null` for unknown or foreign sessions.
  Future<UserSession?> revokeOwnedSession({
    required ObjectId userId,
    required ObjectId sessionId,
  }) async {
    final session = await _sessions.findById(sessionId);
    if (session == null || session.userId != userId) {
      return null;
    }
    if (session.isRevoked) {
      return session;
    }
    return _sessions.revokeById(sessionId, now: _clock().toUtc());
  }
}
