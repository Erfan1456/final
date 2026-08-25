import 'package:home_cleaning_marketplace_api/src/features/auth/http/authenticated_principal.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';

/// Authenticated request context after JWT verification and persisted-user
/// resolution.
///
/// [currentUser] is the authoritative account. Do not serialize it implicitly;
/// HTTP layers must use explicit safe JSON helpers.
class AuthenticatedUserContext {
  /// Creates a scoped context for a role-authorized request.
  const AuthenticatedUserContext({
    required this.principal,
    required this.currentUser,
  });

  /// Verified access-token identity. Role on the principal may be stale.
  final AuthenticatedPrincipal principal;

  /// Current persisted user. Password hash must not be serialized.
  final UserAccount currentUser;
}
