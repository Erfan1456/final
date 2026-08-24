import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAuthPost(context, (auth, json) async {
    final request = SignupRequest.fromJson(json);
    final result = await auth.signUp(
      email: request.email,
      password: request.password,
      role: request.role,
    );
    return jsonSuccess(
      authenticationDataJson(result),
      statusCode: HttpStatus.created,
    );
  });
}
