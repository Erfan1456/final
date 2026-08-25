import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/admin_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final params = context.request.uri.queryParameters;
      final service = context.read<AdminPayoutService>();
      return jsonSuccess(
        await service.list(
          status: params['status'],
          currency: params['currency'],
          cleanerUserId: params['cleaner_user_id'],
          limitRaw: params['limit'],
          after: params['after'],
        ),
      );
    },
  );
}
