import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/http/account_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  final method = context.request.method;
  if (method == HttpMethod.get) {
    return handleAccountRequest(
      context,
      method: HttpMethod.get,
      action: (principal, account) async {
        await account.getCurrentUser(principal.userId);
        final security = context.read<AccountSecurityService>();
        final sessions = await security.listSessions(
          userId: principal.userId,
          currentSessionId: principal.sessionId,
        );
        return jsonSuccess(
          <String, Object>{
            'sessions': [
              for (final session in sessions) accountSessionJson(session),
            ],
          },
          headers: sensitiveNoStoreHeaders,
        );
      },
    );
  }
  if (method == HttpMethod.delete) {
    return handleAccountRequest(
      context,
      method: HttpMethod.delete,
      action: (principal, account) async {
        await account.revokeAllSessions(principal.userId);
        return jsonSuccess(
          const <String, bool>{
            'sessions_revoked': true,
          },
          headers: sensitiveNoStoreHeaders,
        );
      },
    );
  }
  return Future<Response>.value(
    Response(statusCode: HttpStatus.methodNotAllowed),
  );
}
