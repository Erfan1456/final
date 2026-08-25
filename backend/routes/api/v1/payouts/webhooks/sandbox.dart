import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/payout_webhook_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/security/sandbox_payout_webhook_hmac.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in context.request.bytes()) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final headers = context.request.headers;
    final signature =
        headers[SandboxPayoutWebhookHmac.signatureHeaderNameLower] ??
        headers[SandboxPayoutWebhookHmac.signatureHeaderName];
    final webhooks = context.read<PayoutWebhookService>();
    await webhooks.process(
      rawBodyBytes: bytes,
      signatureHeader: signature,
    );
    return jsonSuccess(<String, Object?>{'accepted': true});
  } on Exception catch (error) {
    return mapRoleScopedException(error);
  }
}
