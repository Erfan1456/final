import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/http/account_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAccountRequest(
    context,
    method: HttpMethod.delete,
    action: (principal, account) async {
      await account.revokeAllSessions(principal.userId);
      return jsonSuccess(const <String, bool>{
        'sessions_revoked': true,
      });
    },
  );
}
