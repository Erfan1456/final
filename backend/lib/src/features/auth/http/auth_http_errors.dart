import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
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
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is InvalidJsonBodyException || error is FormatException) {
    return jsonError(
      code: 'invalid_json',
      message: 'Request body must be valid JSON.',
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is UnsupportedMediaTypeException) {
    return jsonError(
      code: 'unsupported_media_type',
      message: 'Content-Type must be application/json.',
      statusCode: HttpStatus.unsupportedMediaType,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is DuplicateUserEmailException) {
    return jsonError(
      code: 'duplicate_email',
      message: 'An account with this email already exists.',
      statusCode: HttpStatus.conflict,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is InvalidCredentialsException) {
    return jsonError(
      code: 'invalid_credentials',
      message: 'Invalid email or password.',
      statusCode: HttpStatus.unauthorized,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is InvalidAccessTokenException) {
    return jsonError(
      code: 'invalid_access_token',
      message: 'Authentication is required.',
      statusCode: HttpStatus.unauthorized,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is AccountUnavailableException) {
    return jsonError(
      code: 'account_unavailable',
      message: 'This account is currently unavailable.',
      statusCode: HttpStatus.forbidden,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is InvalidRefreshCredentialsException ||
      error is RefreshTokenReuseDetectedException ||
      error is InvalidRefreshTokenException) {
    return jsonError(
      code: 'invalid_refresh_token',
      message: 'Refresh token is invalid or expired.',
      statusCode: HttpStatus.unauthorized,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is EmailNotVerifiedException) {
    return jsonError(
      code: 'email_not_verified',
      message: 'Verify your email before signing in.',
      statusCode: HttpStatus.forbidden,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is InvalidAccountActionTokenException) {
    return jsonError(
      code: error.code,
      message: error.message,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is AccountActionDeliveryUnavailableException) {
    return jsonError(
      code: error.code,
      message: error.message,
      statusCode: HttpStatus.serviceUnavailable,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is InvalidCurrentPasswordException) {
    return jsonError(
      code: 'invalid_current_password',
      message: 'Current password is incorrect.',
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is PasswordReuseNotAllowedException) {
    return jsonError(
      code: 'password_reuse_not_allowed',
      message: 'The new password must be different from the current password.',
      statusCode: HttpStatus.conflict,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is SessionNotFoundException) {
    return jsonError(
      code: 'session_not_found',
      message: 'Session was not found.',
      statusCode: HttpStatus.notFound,
      headers: sensitiveNoStoreHeaders,
    );
  }
  if (error is AuthenticationConfigurationException ||
      error is AccessTokenConfigurationException) {
    return jsonError(
      code: 'authentication_unavailable',
      message: 'Authentication is temporarily unavailable.',
      statusCode: HttpStatus.serviceUnavailable,
      headers: sensitiveNoStoreHeaders,
    );
  }
  return jsonError(
    code: 'service_unavailable',
    message: 'Authentication is temporarily unavailable.',
    statusCode: HttpStatus.serviceUnavailable,
    headers: sensitiveNoStoreHeaders,
  );
}
