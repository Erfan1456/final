import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  return jsonSuccess(<String, String>{
    'service': 'home_cleaning_marketplace_api',
    'api': '/api/v1',
  });
}
