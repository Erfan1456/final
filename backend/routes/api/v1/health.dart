import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final config = ServerConfig.fromEnvironment();

  return jsonSuccess(<String, String>{
    'status': 'ok',
    'service': 'home_cleaning_marketplace_api',
    'environment': config.environment,
  });
}
