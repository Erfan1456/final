import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/admin_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String disputeId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(disputeId);
      if (id == null) {
        return disputeNotFoundResponse();
      }
      final disputes = context.read<AdminDisputeService>();
      return jsonSuccess(await disputes.detail(id));
    },
  );
}
