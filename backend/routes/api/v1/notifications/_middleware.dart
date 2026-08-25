import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_middleware.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

Handler middleware(Handler handler) {
  return multiRoleMiddleware(
    handler,
    allowedRoles: {UserRole.customer, UserRole.cleaner, UserRole.admin},
  );
}
