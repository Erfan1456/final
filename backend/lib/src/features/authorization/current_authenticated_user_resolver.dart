import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Resolves the current persisted user after access-token authentication.
class CurrentAuthenticatedUserResolver {
  /// Creates a resolver over [users].
  const CurrentAuthenticatedUserResolver({required UserRepository users})
    : _users = users;

  final UserRepository _users;

  /// Loads [userId] from persistence.
  ///
  /// Missing users fail as [InvalidAccessTokenException]. Suspended and
  /// deactivated accounts throw [AccountUnavailableException].
  Future<UserAccount> resolve(ObjectId userId) async {
    final user = await _users.findById(userId);
    if (user == null) {
      throw const InvalidAccessTokenException();
    }
    if (user.accountStatus != AccountStatus.active) {
      throw const AccountUnavailableException();
    }
    return user;
  }
}
