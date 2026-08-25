import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_token.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/security/account_action_token_crypto.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Newly issued account-action token. [rawToken] is never persisted.
class IssuedAccountAction {
  /// Creates an issued action. Do not log [rawToken].
  const IssuedAccountAction({
    required this.rawToken,
    required this.token,
  });

  /// Opaque raw token returned only to the delivery boundary.
  final String rawToken;

  /// Persisted hashed token metadata.
  final AccountActionToken token;
}

/// Issues, hashes, replaces, and claims account-action tokens.
class AccountActionTokenService {
  /// Creates a service over [tokens].
  AccountActionTokenService({
    required AccountActionTokenRepository tokens,
    AccountActionTokenGenerator? generator,
    AccountActionTokenHasher? hasher,
    DateTime Function()? clock,
  }) : _tokens = tokens,
       _generator = generator ?? AccountActionTokenGenerator(),
       _hasher = hasher ?? AccountActionTokenHasher(),
       _clock = clock ?? _utcNow;

  final AccountActionTokenRepository _tokens;
  final AccountActionTokenGenerator _generator;
  final AccountActionTokenHasher _hasher;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  /// SHA-256 lowercase hex of [rawToken]. Never log [rawToken].
  String hashRawToken(String rawToken) => _hasher.hash(rawToken);

  /// Revokes live tokens for the same user and purpose, then inserts a new
  /// hashed token.
  Future<IssuedAccountAction> issue({
    required ObjectId userId,
    required AccountActionPurpose purpose,
  }) async {
    final now = _clock().toUtc();
    final rawToken = _generator.generate();
    final tokenHash = _hasher.hash(rawToken);
    await _tokens.revokeLiveForUserAndPurpose(
      userId: userId,
      purpose: purpose,
      now: now,
    );
    final token = AccountActionToken(
      id: ObjectId(),
      userId: userId,
      purpose: purpose,
      tokenHash: tokenHash,
      expiresAt: now.add(AccountActionPolicy.lifetimeFor(purpose)),
      createdAt: now,
    );
    final stored = await _tokens.create(token);
    return IssuedAccountAction(rawToken: rawToken, token: stored);
  }

  /// Atomically claims a live token or throws a generic invalid-token error.
  Future<AccountActionToken> claim({
    required String rawToken,
    required AccountActionPurpose purpose,
  }) async {
    if (rawToken.isEmpty) {
      throw const InvalidAccountActionTokenException();
    }
    final now = _clock().toUtc();
    final claimed = await _tokens.claimByTokenHash(
      tokenHash: _hasher.hash(rawToken),
      purpose: purpose,
      now: now,
    );
    if (claimed == null) {
      throw const InvalidAccountActionTokenException();
    }
    return claimed;
  }

  /// Returns a live token for reuse checks without marking it used.
  Future<AccountActionToken?> findLive({
    required String rawToken,
    required AccountActionPurpose purpose,
  }) {
    if (rawToken.isEmpty) {
      return Future<AccountActionToken?>.value();
    }
    return _tokens.findLiveByTokenHash(
      tokenHash: _hasher.hash(rawToken),
      purpose: purpose,
      now: _clock().toUtc(),
    );
  }
}
