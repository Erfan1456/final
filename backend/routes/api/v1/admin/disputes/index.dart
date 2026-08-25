import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/admin_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final disputes = context.read<AdminDisputeService>();
      return jsonSuccess(
        await disputes.list(
          status: query['status'],
          category: query['category'],
          bookingId: query['booking_id'],
          customerUserId: query['customer_user_id'],
          cleanerUserId: query['cleaner_user_id'],
          limitRaw: query['limit'],
          after: query['after'],
        ),
      );
    },
  );
}
