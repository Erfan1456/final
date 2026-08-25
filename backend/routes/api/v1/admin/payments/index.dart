import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final payments = context.read<AdminPaymentService>();
      final data = await payments.list(
        status: query['status'],
        provider: query['provider'],
        currency: query['currency'],
        bookingId: query['booking_id'],
        customerUserId: query['customer_user_id'],
        limitRaw: query['limit'],
        after: query['after'],
      );
      return jsonSuccess(data);
    },
  );
}
