import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAuthPost(context, (auth, json) async {
    final request = LogoutRequest.fromJson(json);
    await auth.logout(request.refreshToken);
    return jsonSuccess(
      const <String, bool>{'logged_out': true},
      headers: sensitiveNoStoreHeaders,
    );
  });
}
