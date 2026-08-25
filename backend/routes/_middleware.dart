import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/http/cors_headers.dart';

ServerConfig? _sharedConfig;
MongoDatabase? _sharedMongo;

/// Test-only seam so CORS/middleware tests inject [ServerConfig] instead of
/// loading the developer's private `.env`.
///
/// Production Dart Frog never calls this. Passing [config] uses that value;
/// omitting it restores lazy environment loading.
void resetMiddlewareCaches({ServerConfig? config}) {
  _sharedConfig = config;
  _sharedMongo = null;
}

ServerConfig _serverConfig() {
  return _sharedConfig ??= ServerConfig.fromEnvironment(
    const EnvironmentLoader().load(),
  );
}

MongoDatabase _mongoDatabase() {
  return _sharedMongo ??= MongoDatabase(config: _serverConfig());
}

Handler middleware(Handler handler) {
  final config = _serverConfig();
  final mongo = _mongoDatabase();
  final withProviders = handler
      .use(provider<ServerConfig>((_) => config))
      .use(provider<MongoDatabase>((_) => mongo));

  return (context) async {
    final origin = config.allowedOriginHeader(
      context.request.headers['origin'],
    );

    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: corsHeaders(origin),
      );
    }

    final response = await withProviders(context);
    final extraHeaders = corsHeaders(origin);
    if (extraHeaders.isEmpty) {
      return response;
    }

    return response.copyWith(
      headers: <String, Object?>{
        ...response.headers,
        ...extraHeaders,
      },
    );
  };
}
