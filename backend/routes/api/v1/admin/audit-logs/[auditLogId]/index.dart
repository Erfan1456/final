import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String auditLogId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(auditLogId);
      if (id == null) {
        return auditLogNotFoundResponse();
      }
      final audit = context.read<AuditLogService>();
      return jsonSuccess(await audit.detail(id));
    },
  );
}
