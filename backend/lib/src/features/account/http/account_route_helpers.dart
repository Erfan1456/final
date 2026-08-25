import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/current_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/authenticated_principal.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';

/// Runs a protected account route with shared method and error mapping.
Future<Response> handleAccountRequest(
  RequestContext context, {
  required HttpMethod method,
  required Future<Response> Function(
    AuthenticatedPrincipal principal,
    CurrentAccountService account,
  )
  action,
}) async {
  if (context.request.method != method) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final principal = context.read<AuthenticatedPrincipal>();
    final account = context.read<CurrentAccountService>();
    return await action(principal, account);
  } on InvalidAccessTokenException catch (error) {
    return mapAuthException(error);
  } on AccountUnavailableException catch (error) {
    return mapAuthException(error);
  } on AuthenticationConfigurationException catch (error) {
    return mapAuthException(error);
  } on Exception catch (error) {
    return mapAuthException(error);
  }
}
