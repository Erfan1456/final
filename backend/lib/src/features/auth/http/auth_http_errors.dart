import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/user_session_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

/// Maps authentication application failures to the JSON error envelope.
Response mapAuthException(Exception error) {
  if (error is InvalidAuthInputException) {
    return jsonError(
      code: error.code,
      message: error.message,
    );
  }
  if (error is InvalidJsonBodyException || error is FormatException) {
    return jsonError(
      code: 'invalid_json',
      message: 'Request body must be valid JSON.',
    );
  }
  if (error is UnsupportedMediaTypeException) {
    return jsonError(
      code: 'unsupported_media_type',
      message: 'Content-Type must be application/json.',
      statusCode: HttpStatus.unsupportedMediaType,
    );
  }
  if (error is DuplicateUserEmailException) {
    return jsonError(
      code: 'duplicate_email',
      message: 'An account with this email already exists.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidCredentialsException) {
    return jsonError(
      code: 'invalid_credentials',
      message: 'Invalid email or password.',
      statusCode: HttpStatus.unauthorized,
    );
  }
  if (error is InvalidAccessTokenException) {
    return jsonError(
      code: 'invalid_access_token',
      message: 'Authentication is required.',
      statusCode: HttpStatus.unauthorized,
    );
  }
  if (error is AccountUnavailableException) {
    return jsonError(
      code: 'account_unavailable',
      message: 'This account is currently unavailable.',
      statusCode: HttpStatus.forbidden,
    );
  }
  if (error is InvalidRefreshCredentialsException ||
      error is RefreshTokenReuseDetectedException ||
      error is InvalidRefreshTokenException) {
    return jsonError(
      code: 'invalid_refresh_token',
      message: 'Refresh token is invalid or expired.',
      statusCode: HttpStatus.unauthorized,
    );
  }
  if (error is AuthenticationConfigurationException ||
      error is AccessTokenConfigurationException) {
    return jsonError(
      code: 'authentication_unavailable',
      message: 'Authentication is temporarily unavailable.',
      statusCode: HttpStatus.serviceUnavailable,
    );
  }
  return jsonError(
    code: 'service_unavailable',
    message: 'Authentication is temporarily unavailable.',
    statusCode: HttpStatus.serviceUnavailable,
  );
}
