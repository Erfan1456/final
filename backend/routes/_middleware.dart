import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/configuration_validation.dart';
import 'package:home_cleaning_marketplace_api/src/config/environment_loader.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/http/cors_headers.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';
import 'package:home_cleaning_marketplace_api/src/http/request_id.dart';
import 'package:home_cleaning_marketplace_api/src/http/security_headers.dart';

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
  if (_sharedConfig != null) {
    return _sharedConfig!;
  }
  final loaded = ServerConfig.fromEnvironment(
    const EnvironmentLoader().load(),
  );
  validateServerConfig(loaded);
  return _sharedConfig = loaded;
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
    final requestId = RequestId.resolve(
      context.request.headers[RequestId.headerName],
    );
    final origin = config.allowedOriginHeader(
      context.request.headers['origin'],
    );
    final baseHeaders = <String, String>{
      ...securityResponseHeaders(),
      RequestId.headerName: requestId,
      ...corsHeaders(origin),
    };

    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: baseHeaders,
      );
    }

    try {
      final scoped = context.provide<String>(() => requestId);
      final response = await withProviders(scoped);
      return response.copyWith(
        headers: <String, Object?>{
          ...response.headers,
          ...baseHeaders,
        },
      );
    } catch (_) {
      // Never leak exception details to clients.
      if (!config.isProduction) {
        stderr.writeln('Unhandled request error request_id=$requestId');
      }
      return jsonError(
        statusCode: HttpStatus.internalServerError,
        code: 'internal_error',
        message: 'Something went wrong. Please try again.',
        headers: baseHeaders,
      );
    }
  };
}
