import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAccountActionPost(context, (security, json) async {
    final request = ConfirmPasswordResetRequest.fromJson(json);
    await security.confirmPasswordReset(
      rawToken: request.token,
      newPassword: request.newPassword,
    );
    return jsonSuccess(
      const <String, bool>{'reauthentication_required': true},
      headers: sensitiveNoStoreHeaders,
    );
  });
}
