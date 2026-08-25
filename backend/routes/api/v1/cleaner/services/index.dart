import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/application/cleaner_service_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final management = context.read<CleanerServiceManagementService>();
      final items = await management.list(scoped.currentUser);
      return jsonSuccess(<String, Object>{'items': items});
    },
  );
}
