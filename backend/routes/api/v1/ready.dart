import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final mongo = context.read<MongoDatabase>();
  if (!mongo.isConfigured) {
    return _unavailable();
  }

  final isReady = await mongo.ping();
  if (!isReady) {
    return _unavailable();
  }

  return jsonSuccess(const <String, String>{
    'status': 'ready',
  });
}

Response _unavailable() {
  return jsonError(
    code: 'database_unavailable',
    message: 'Service is not ready.',
    statusCode: HttpStatus.serviceUnavailable,
  );
}
