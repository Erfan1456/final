import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/auth_session_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent current-account use cases for protected routes.
abstract interface class CurrentAccountService {
  /// Returns the persisted account for [userId].
  ///
  /// Missing users fail as authentication failures. Suspended and deactivated
  /// accounts throw [AccountUnavailableException].
  Future<UserAccount> getCurrentUser(ObjectId userId);

  /// Revokes every refresh session owned by [userId].
  Future<void> revokeAllSessions(ObjectId userId);
}

/// Production current-account use cases.
class CurrentAccountServiceImpl implements CurrentAccountService {
  /// Creates a service over [users] and [sessions].
  CurrentAccountServiceImpl({
    required UserRepository users,
    required AuthSessionService sessions,
  }) : _users = users,
       _sessions = sessions;

  final UserRepository _users;
  final AuthSessionService _sessions;

  @override
  Future<UserAccount> getCurrentUser(ObjectId userId) async {
    final user = await _users.findById(userId);
    if (user == null) {
      throw const InvalidAccessTokenException();
    }
    if (user.accountStatus != AccountStatus.active) {
      throw const AccountUnavailableException();
    }
    return user;
  }

  @override
  Future<void> revokeAllSessions(ObjectId userId) async {
    await _sessions.revokeAllForUser(userId);
  }
}

/// Current-account service used when MongoDB is unconfigured or unusable.
class UnconfiguredCurrentAccountService implements CurrentAccountService {
  /// Creates a service that fails every use case before persistence.
  const UnconfiguredCurrentAccountService();

  @override
  Future<UserAccount> getCurrentUser(ObjectId userId) async {
    throw const AuthenticationConfigurationException();
  }

  @override
  Future<void> revokeAllSessions(ObjectId userId) async {
    throw const AuthenticationConfigurationException();
  }
}
