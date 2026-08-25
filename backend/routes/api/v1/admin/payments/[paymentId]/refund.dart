import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String paymentId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(paymentId);
      if (id == null) {
        return paymentNotFoundResponse();
      }
      final json = await parseJsonObject(context.request);
      final headers = context.request.headers;
      final payments = context.read<AdminPaymentService>();
      final result = await payments.refund(
        user: scoped.currentUser,
        paymentId: id,
        idempotencyKeyRaw:
            headers['idempotency-key'] ?? headers['Idempotency-Key'],
        amountRaw: json['amount_minor'],
        reasonRaw: json['reason'],
      );
      return jsonSuccess(
        result.payment,
        statusCode: result.created ? HttpStatus.ok : HttpStatus.ok,
      );
    },
  );
}
