import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/application/admin_user_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String userId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(userId);
      if (id == null) {
        return userNotFoundResponse();
      }
      final users = context.read<AdminUserManagementService>();
      return jsonSuccess(await users.getUser(id));
    },
  );
}
