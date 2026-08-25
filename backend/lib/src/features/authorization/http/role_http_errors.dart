import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

/// Maps role-scoped application failures to the JSON error envelope.
Response mapRoleScopedException(Exception error) {
  if (error is ForbiddenException) {
    return jsonError(
      code: 'forbidden',
      message: 'You do not have permission to perform this action.',
      statusCode: HttpStatus.forbidden,
    );
  }
  if (error is ProfileValidationException) {
    return jsonError(code: error.code, message: error.message);
  }
  if (error is CustomerProfileRequiredException) {
    return jsonError(
      code: 'customer_profile_required',
      message: 'Create your customer profile before setting a default address.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is AddressLimitReachedException) {
    return jsonError(
      code: 'address_limit_reached',
      message: 'You can save at most 20 addresses.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is AddressNotFoundException) {
    return jsonError(
      code: 'address_not_found',
      message: 'Address was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is CleanerProfileRequiredException) {
    return jsonError(
      code: 'cleaner_profile_required',
      message: 'Create your cleaner profile before submitting for review.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is CleanerProfileLockedException) {
    return jsonError(
      code: 'cleaner_profile_locked',
      message: 'This cleaner profile cannot be edited in its current state.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidOnboardingStateException) {
    return jsonError(
      code: 'invalid_onboarding_state',
      message: 'This onboarding action is not allowed in the current state.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is CleanerApplicationNotFoundException) {
    return jsonError(
      code: 'cleaner_application_not_found',
      message: 'Cleaner application was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is InvalidAccessTokenException ||
      error is AccountUnavailableException ||
      error is AuthenticationConfigurationException ||
      error is AccessTokenConfigurationException ||
      error is InvalidJsonBodyException ||
      error is UnsupportedMediaTypeException ||
      error is InvalidAuthInputException) {
    return mapAuthException(error);
  }
  return jsonError(
    code: 'service_unavailable',
    message: 'This service is temporarily unavailable.',
    statusCode: HttpStatus.serviceUnavailable,
  );
}
