import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/current_authenticated_user_resolver.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/role_authorizer.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// JWT authentication plus persisted-user role authorization.
class RoleRequestAuthorizer {
  /// Creates an authorizer over [authenticator] and [resolver].
  const RoleRequestAuthorizer({
    required AccessAuthenticator authenticator,
    required CurrentAuthenticatedUserResolver resolver,
  }) : _authenticator = authenticator,
       _resolver = resolver;

  final AccessAuthenticator _authenticator;
  final CurrentAuthenticatedUserResolver _resolver;

  /// Verifies the Bearer token, loads the persisted user, and checks
  /// [requiredRole].
  ///
  /// Persisted user role is authoritative. The JWT role is ignored
  /// for authorization.
  Future<AuthenticatedUserContext> authorize({
    required String? authorizationHeader,
    required UserRole requiredRole,
  }) async {
    final principal = _authenticator.authenticate(authorizationHeader);
    final user = await _resolver.resolve(principal.userId);
    RoleAuthorizer.require(user, requiredRole);
    return AuthenticatedUserContext(principal: principal, currentUser: user);
  }

  /// Verifies the Bearer token, loads the persisted user, and requires one of
  /// [allowedRoles]. Persisted role is authoritative.
  Future<AuthenticatedUserContext> authorizeAny({
    required String? authorizationHeader,
    required Set<UserRole> allowedRoles,
  }) async {
    final principal = _authenticator.authenticate(authorizationHeader);
    final user = await _resolver.resolve(principal.userId);
    RoleAuthorizer.requireAny(user, allowedRoles);
    return AuthenticatedUserContext(principal: principal, currentUser: user);
  }
}
