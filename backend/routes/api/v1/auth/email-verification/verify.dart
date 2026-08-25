import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAccountActionPost(context, (security, json) async {
    final request = VerifyEmailRequest.fromJson(json);
    await security.verifyEmail(request.token);
    return jsonSuccess(
      const <String, bool>{'email_verified': true},
      headers: sensitiveNoStoreHeaders,
    );
  });
}
