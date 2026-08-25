import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// Authorizes a request using the persisted user role.
///
/// JWT role claims are not used here because they can be stale.
abstract final class RoleAuthorizer {
  /// Requires the persisted user role to equal [requiredRole].
  static void require(UserAccount user, UserRole requiredRole) {
    if (user.role != requiredRole) {
      throw const ForbiddenException();
    }
  }
}
