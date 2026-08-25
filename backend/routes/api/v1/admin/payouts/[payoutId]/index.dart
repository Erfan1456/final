import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/admin_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String payoutId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(payoutId);
      if (id == null) {
        return payoutNotFoundResponse();
      }
      final service = context.read<AdminPayoutService>();
      return jsonSuccess(await service.detail(id));
    },
  );
}
