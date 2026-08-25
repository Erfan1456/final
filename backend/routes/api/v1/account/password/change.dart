import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/http/account_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAccountRequest(
    context,
    method: HttpMethod.post,
    action: (principal, account) async {
      await account.getCurrentUser(principal.userId);
      final json = await parseJsonObject(context.request);
      final request = ChangePasswordRequest.fromJson(json);
      final security = context.read<AccountSecurityService>();
      await security.changePassword(
        userId: principal.userId,
        currentPassword: request.currentPassword,
        newPassword: request.newPassword,
      );
      return jsonSuccess(
        const <String, bool>{'reauthentication_required': true},
        headers: sensitiveNoStoreHeaders,
      );
    },
  );
}
