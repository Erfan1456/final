import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/application/audit_log_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final audit = context.read<AuditLogService>();
      return jsonSuccess(
        await audit.list(
          actorUserId: query['actor_user_id'],
          action: query['action'],
          targetType: query['target_type'],
          targetId: query['target_id'],
          from: query['from'],
          to: query['to'],
          limitRaw: query['limit'],
          after: query['after'],
        ),
      );
    },
  );
}
