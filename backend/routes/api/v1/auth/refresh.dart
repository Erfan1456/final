import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAuthPost(context, (auth, json) async {
    final request = RefreshRequest.fromJson(json);
    final tokens = await auth.refresh(request.refreshToken);
    return jsonSuccess(
      refreshedTokensDataJson(tokens),
      headers: sensitiveNoStoreHeaders,
    );
  });
}
