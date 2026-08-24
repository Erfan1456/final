import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final auth = await AuthComposition.resolve(
      config: context.read<ServerConfig>(),
      mongo: context.read<MongoDatabase>(),
    );
    return handler(
      context.provide<AuthenticationService>(() => auth),
    );
  };
}
