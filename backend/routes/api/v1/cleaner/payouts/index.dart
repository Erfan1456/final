import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/cleaner_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final service = context.read<CleanerPayoutService>();
      if (context.request.method == HttpMethod.get) {
        final params = context.request.uri.queryParameters;
        return jsonSuccess(
          await service.listPayouts(
            user: scoped.currentUser,
            status: params['status'],
            currency: params['currency'],
            limitRaw: params['limit'],
            after: params['after'],
          ),
        );
      }
      final json = await parseJsonObject(context.request);
      final headers = context.request.headers;
      final result = await service.requestPayout(
        user: scoped.currentUser,
        idempotencyKeyRaw:
            headers['idempotency-key'] ?? headers['Idempotency-Key'],
        amountRaw: json['amount_minor'],
        currencyRaw: json['currency_code'],
      );
      return jsonSuccess(
        <String, Object?>{'payout': result.payout},
        statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      );
    },
  );
}
