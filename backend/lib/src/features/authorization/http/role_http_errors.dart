import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/tokens/access_token_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/service_exceptions.dart';
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
  if (error is ServiceNotFoundException) {
    return jsonError(
      code: 'service_not_found',
      message: 'Service was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is CleanerNotApprovedException) {
    return jsonError(
      code: 'cleaner_not_approved',
      message:
          'Your cleaner account must be approved before managing services.',
      statusCode: HttpStatus.forbidden,
    );
  }
  if (error is CleanerServiceNotFoundException) {
    return jsonError(
      code: 'cleaner_service_not_found',
      message: 'Service offering was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is AvailabilityNotFoundException) {
    return jsonError(
      code: 'availability_not_found',
      message: 'Availability slot was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is AvailabilityOverlapException) {
    return jsonError(
      code: 'availability_overlap',
      message: 'This availability window overlaps another slot.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is AvailabilityLimitReachedException) {
    return jsonError(
      code: 'availability_limit_reached',
      message: 'You can save at most 180 future availability slots.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidAvailabilityWindowException) {
    return jsonError(
      code: 'invalid_availability_window',
      message: error.message,
    );
  }
  if (error is AvailabilityReservedException) {
    return jsonError(
      code: 'availability_reserved',
      message: 'This availability slot is reserved by an active booking.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is BookingNotFoundException) {
    return jsonError(
      code: 'booking_not_found',
      message: 'Booking was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is AvailabilityUnavailableException) {
    return jsonError(
      code: 'availability_unavailable',
      message: 'That availability slot is no longer available.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidBookingStateException) {
    return jsonError(
      code: 'invalid_booking_state',
      message: 'This booking action is not allowed in the current state.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is IdempotencyKeyRequiredException) {
    return jsonError(
      code: 'idempotency_key_required',
      message: 'Idempotency-Key is required.',
    );
  }
  if (error is InvalidIdempotencyKeyException) {
    return jsonError(
      code: 'invalid_idempotency_key',
      message: 'Idempotency-Key is invalid.',
    );
  }
  if (error is IdempotencyKeyReusedException) {
    return jsonError(
      code: 'idempotency_key_reused',
      message: 'Idempotency-Key was already used for a different request.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidCustomerNotesException) {
    return jsonError(
      code: 'invalid_customer_notes',
      message: error.message,
    );
  }
  if (error is PaymentNotFoundException) {
    return jsonError(
      code: 'payment_not_found',
      message: 'Payment was not found.',
      statusCode: HttpStatus.notFound,
    );
  }
  if (error is BookingNotPayableException) {
    return jsonError(
      code: 'booking_not_payable',
      message: 'This booking cannot be paid in its current state.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is PaymentAlreadyActiveException) {
    return jsonError(
      code: 'payment_already_active',
      message: 'A payment attempt is already in progress for this booking.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is PaymentAlreadyPaidException) {
    return jsonError(
      code: 'payment_already_paid',
      message: 'This booking already has a successful payment.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is PaymentProviderUnavailableException) {
    return jsonError(
      code: 'payment_provider_unavailable',
      message: 'Payment is temporarily unavailable.',
      statusCode: HttpStatus.serviceUnavailable,
    );
  }
  if (error is InvalidWebhookSignatureException) {
    return jsonError(
      code: 'invalid_webhook_signature',
      message: 'Webhook signature is invalid.',
      statusCode: HttpStatus.unauthorized,
    );
  }
  if (error is WebhookEventConflictException) {
    return jsonError(
      code: 'webhook_event_conflict',
      message: 'Webhook event conflict.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is PaymentIntegrityMismatchException) {
    return jsonError(
      code: 'payment_integrity_mismatch',
      message: 'Payment details do not match this event.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidPaymentStateException) {
    return jsonError(
      code: 'invalid_payment_state',
      message: 'This payment action is not allowed in the current state.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is PaymentRefundFailedException) {
    return jsonError(
      code: 'payment_refund_failed',
      message: 'The refund could not be completed.',
      statusCode: HttpStatus.conflict,
    );
  }
  if (error is InvalidRefundAmountException) {
    return jsonError(
      code: 'invalid_refund_amount',
      message: 'Refund amount is invalid.',
    );
  }
  if (error is InvalidRefundReasonException) {
    return jsonError(
      code: 'invalid_refund_reason',
      message: error.message,
    );
  }
  if (error is MalformedWebhookException) {
    return jsonError(
      code: 'invalid_json',
      message: 'Request body must be valid JSON.',
    );
  }
  if (error is CleanerNotFoundException) {
    return jsonError(
      code: 'cleaner_not_found',
      message: 'Cleaner was not found.',
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
