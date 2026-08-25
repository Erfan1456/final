import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/http/account_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAccountRequest(
    context,
    method: HttpMethod.get,
    action: (principal, account) async {
      final user = await account.getCurrentUser(principal.userId);
      return jsonSuccess(<String, Object>{
        'user': authUserJson(user),
      });
    },
  );
}
