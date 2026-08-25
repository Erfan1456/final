import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String paymentId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(paymentId);
      if (id == null) {
        return paymentNotFoundResponse();
      }
      final payments = context.read<AdminPaymentService>();
      final data = await payments.detail(id);
      return jsonSuccess(data);
    },
  );
}
