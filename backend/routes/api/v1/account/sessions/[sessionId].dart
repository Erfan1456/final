import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/http/account_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String sessionId) {
  return handleAccountRequest(
    context,
    method: HttpMethod.delete,
    action: (principal, account) async {
      await account.getCurrentUser(principal.userId);
      final id = parsePathObjectId(sessionId);
      if (id == null) {
        throw const SessionNotFoundException();
      }
      final security = context.read<AccountSecurityService>();
      final result = await security.revokeSession(
        userId: principal.userId,
        sessionId: id,
        currentSessionId: principal.sessionId,
      );
      return jsonSuccess(
        <String, bool>{
          'current_session_revoked': result.currentSessionRevoked,
        },
        headers: sensitiveNoStoreHeaders,
      );
    },
  );
}
