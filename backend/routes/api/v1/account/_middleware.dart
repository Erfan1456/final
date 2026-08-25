import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/current_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/access_authenticator.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/authenticated_principal.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final config = context.read<ServerConfig>();
    final tokens = AccountComposition.accessTokens(config);
    final authenticator = AccessAuthenticator(tokens: tokens);

    final AuthenticatedPrincipal principal;
    try {
      principal = authenticator.authenticate(
        context.request.headers[HttpHeaders.authorizationHeader],
      );
    } on InvalidAccessTokenException catch (error) {
      return mapAuthException(error);
    } on AccessTokenConfigurationException catch (error) {
      return mapAuthException(error);
    }

    final account = await AccountComposition.resolve(
      mongo: context.read<MongoDatabase>(),
    );

    return handler(
      context
          .provide<AuthenticatedPrincipal>(() => principal)
          .provide<CurrentAccountService>(() => account),
    );
  };
}
