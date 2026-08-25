import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/sandbox_payment_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String paymentId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final id = parsePathObjectId(paymentId);
    if (id == null) {
      return paymentNotFoundResponse();
    }
    final json = await parseJsonObject(context.request);
    final simulation = context.read<SandboxPaymentSimulationService>();
    final payment = await simulation.simulate(
      paymentId: id,
      resultRaw: json['result'],
    );
    return jsonSuccess(<String, Object?>{'payment': payment});
  } on Exception catch (error) {
    return mapRoleScopedException(error);
  }
}
