import 'package:home_cleaning_marketplace_api/src/features/account/application/current_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Test double for protected account route tests. Never contacts MongoDB Atlas.
class FakeCurrentAccountService implements CurrentAccountService {
  /// Creates a fake with optional canned results or errors.
  FakeCurrentAccountService();

  /// Account returned by [getCurrentUser] when [nextError] is null.
  UserAccount? nextUser;

  /// When set, the next use-case throws this exception.
  Exception? nextError;

  int getCurrentUserCalls = 0;
  int revokeAllSessionsCalls = 0;
  ObjectId? lastUserId;

  @override
  Future<UserAccount> getCurrentUser(ObjectId userId) async {
    getCurrentUserCalls += 1;
    lastUserId = userId;
    _throwIfNeeded();
    return nextUser!;
  }

  @override
  Future<void> revokeAllSessions(ObjectId userId) async {
    revokeAllSessionsCalls += 1;
    lastUserId = userId;
    _throwIfNeeded();
  }

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }
}
