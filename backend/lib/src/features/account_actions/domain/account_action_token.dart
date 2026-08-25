import 'package:mongo_dart/mongo_dart.dart';

import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';

/// Persisted hashed one-time account-action token.
class AccountActionToken {
  /// Creates a domain token. [tokenHash] is SHA-256 hex only.
  const AccountActionToken({
    required this.id,
    required this.userId,
    required this.purpose,
    required this.tokenHash,
    required this.expiresAt,
    required this.createdAt,
    this.claimedAt,
    this.revokedAt,
  });

  /// Document id.
  final ObjectId id;

  /// Owning user.
  final ObjectId userId;

  /// Verification or password reset.
  final AccountActionPurpose purpose;

  /// SHA-256 lowercase hex of the raw token. Never the raw token.
  final String tokenHash;

  /// UTC expiry. Application still checks this because TTL is async.
  final DateTime expiresAt;

  /// UTC claim time when consumed.
  final DateTime? claimedAt;

  /// UTC revoke time when superseded.
  final DateTime? revokedAt;

  /// UTC insert time.
  final DateTime createdAt;

  /// True when the token is still eligible to be claimed.
  bool isLiveAt(DateTime now) {
    return claimedAt == null && revokedAt == null && expiresAt.isAfter(now);
  }
}
