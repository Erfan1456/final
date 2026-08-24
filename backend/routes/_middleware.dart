import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/http/cors_headers.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final config = ServerConfig.fromEnvironment();
    final origin = config.allowedOriginHeader(
      context.request.headers['origin'],
    );

    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: corsHeaders(origin),
      );
    }

    final response = await handler(context);
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
