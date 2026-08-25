import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// JSON success envelope: `{ "success": true, "data": ... }`.
Response jsonSuccess(
  Object? data, {
  int statusCode = HttpStatus.ok,
  Map<String, String>? headers,
}) {
  return Response(
    statusCode: statusCode,
    body: jsonEncode(<String, Object?>{
      'success': true,
      'data': data,
    }),
    headers: <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.toString(),
      ...?headers,
    },
  );
}

/// Cache headers for responses that may contain tokens or action secrets.
const Map<String, String> sensitiveNoStoreHeaders = <String, String>{
  HttpHeaders.cacheControlHeader: 'no-store',
  'pragma': 'no-cache',
};

/// JSON error envelope: `{ "success": false, "error": { "code", "message" } }`.
Response jsonError({
  required String code,
  required String message,
  int statusCode = HttpStatus.badRequest,
  Map<String, String>? headers,
}) {
  return Response(
    statusCode: statusCode,
    body: jsonEncode(<String, Object>{
      'success': false,
      'error': <String, String>{
        'code': code,
        'message': message,
      },
    }),
    headers: <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.toString(),
      ...?headers,
    },
  );
}
