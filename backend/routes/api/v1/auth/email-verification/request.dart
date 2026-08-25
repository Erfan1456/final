import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_json.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_requests.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleAccountActionPost(context, (security, json) async {
    final request = EmailActionRequest.fromJson(json);
    final result = await security.requestEmailVerification(request.email);
    return jsonSuccess(
      accountActionRequestDataJson(
        message: AccountSecurityServiceImpl.verificationRequestMessage,
        developmentAction: result.developmentAction,
      ),
      headers: sensitiveNoStoreHeaders,
    );
  });
}
