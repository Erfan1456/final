import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/create_user_account_data.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persistence contract for upcoming authentication.
///
/// Email lookup methods accept a caller-supplied email and normalize it
/// internally (trim + lowercase). Callers must not pre-normalize
/// inconsistently.
abstract class UserRepository {
  /// Returns the account with MongoDB `_id` equal to [id], or `null`.
  Future<UserAccount?> findById(ObjectId id);

  /// Returns the account whose normalized email matches [email], or `null`.
  Future<UserAccount?> findByEmail(String email);

  /// Whether an account already exists for the normalized form of [email].
  Future<bool> emailExists(String email);

  /// Returns accounts whose `_id` is in [ids]. Missing ids are omitted.
  Future<List<UserAccount>> findByIds(Iterable<ObjectId> ids);

  /// Inserts a new account. Duplicate normalized emails fail with
  /// [DuplicateUserEmailException].
  Future<UserAccount> create(CreateUserAccountData data);

  /// Replaces only `password_hash` and `updated_at` for [userId].
  ///
  /// Does not change role, status, or email fields.
  Future<void> updatePasswordHash({
    required ObjectId userId,
    required String passwordHash,
    required DateTime updatedAt,
  });

  /// Sets `email_verified` to true for [userId]. Idempotent.
  Future<UserAccount> markEmailVerified({
    required ObjectId userId,
    required DateTime updatedAt,
  });

  /// Admin user list, `_id` descending, optional exact-email filter.
  Future<UserAccountPage> adminPage({
    required int limit,
    UserRole? role,
    AccountStatus? status,
    String? emailNormalized,
    ObjectId? after,
  });

  /// Conditional `active` → `suspended` for a non-admin account.
  Future<UserAccount?> setActiveToSuspended({
    required ObjectId userId,
    required DateTime now,
  });

  /// Conditional `suspended` → `active` for a non-admin account.
  Future<UserAccount?> setSuspendedToActive({
    required ObjectId userId,
    required DateTime now,
  });

  /// Conditional `active`/`suspended` → `deactivated` for a non-admin account.
  Future<UserAccount?> setActiveOrSuspendedToDeactivated({
    required ObjectId userId,
    required DateTime now,
  });
}

/// One keyset page of user accounts.
class UserAccountPage {
  /// Creates a page of [items] with an optional [nextCursor].
  const UserAccountPage({required this.items, required this.nextCursor});

  /// Accounts on this page.
  final List<UserAccount> items;

  /// Hex `_id` of the last item when another page may exist.
  final String? nextCursor;
}
