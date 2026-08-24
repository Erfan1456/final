import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/authentication_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';

/// Runs a POST-only auth route with shared JSON parsing and error mapping.
Future<Response> handleAuthPost(
  RequestContext context,
  Future<Response> Function(
    AuthenticationService auth,
    Map<String, dynamic> json,
  )
  action,
) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final json = await parseJsonObject(context.request);
    final auth = context.read<AuthenticationService>();
    return await action(auth, json);
  } on InvalidAuthInputException catch (error) {
    return mapAuthException(error);
  } on InvalidJsonBodyException catch (error) {
    return mapAuthException(error);
  } on UnsupportedMediaTypeException catch (error) {
    return mapAuthException(error);
  } on DuplicateUserEmailException catch (error) {
    return mapAuthException(error);
  } on InvalidCredentialsException catch (error) {
    return mapAuthException(error);
  } on AccountUnavailableException catch (error) {
    return mapAuthException(error);
  } on InvalidRefreshCredentialsException catch (error) {
    return mapAuthException(error);
  } on AuthenticationConfigurationException catch (error) {
    return mapAuthException(error);
  } on Exception catch (error) {
    return mapAuthException(error);
  }
}

/// Parses a JSON object body. Does not log the body.
Future<Map<String, dynamic>> parseJsonObject(Request request) async {
  if (!_isJsonContentType(request.headers['content-type'])) {
    throw const UnsupportedMediaTypeException();
  }

  final String raw;
  try {
    raw = await request.body();
  } on Exception {
    throw const InvalidJsonBodyException();
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw const InvalidJsonBodyException();
  }

  if (decoded is! Map) {
    throw const InvalidJsonBodyException();
  }

  return Map<String, dynamic>.from(decoded);
}

bool _isJsonContentType(String? value) {
  if (value == null || value.isEmpty) {
    return false;
  }
  final mime = value.split(';').first.trim().toLowerCase();
  return mime == 'application/json';
}
