import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/customer_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String bookingId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(bookingId);
      if (id == null) {
        return bookingNotFoundResponse();
      }
      final payments = context.read<CustomerPaymentService>();
      if (context.request.method == HttpMethod.get) {
        final data = await payments.getPayment(
          user: scoped.currentUser,
          bookingId: id,
        );
        return jsonSuccess(data);
      }
      final headers = context.request.headers;
      final result = await payments.startPayment(
        user: scoped.currentUser,
        bookingId: id,
        idempotencyKeyRaw:
            headers['idempotency-key'] ?? headers['Idempotency-Key'],
      );
      return jsonSuccess(
        <String, Object?>{'payment': result.payment},
        statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      );
    },
  );
}
