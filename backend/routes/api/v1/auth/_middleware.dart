import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/account/application/account_security_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final config = context.read<ServerConfig>();
    final mongo = context.read<MongoDatabase>();
    final auth = await AuthComposition.resolve(
      config: config,
      mongo: mongo,
    );
    final security = await AuthComposition.resolveSecurity(
      config: config,
      mongo: mongo,
    );
    return handler(
      context
          .provide<AuthenticationService>(() => auth)
          .provide<AccountSecurityService>(() => security),
    );
  };
}
