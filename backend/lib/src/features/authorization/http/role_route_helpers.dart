import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Runs a role-scoped route with method checking and shared error mapping.
Future<Response> handleRoleRequest(
  RequestContext context, {
  required Set<HttpMethod> methods,
  required Future<Response> Function(AuthenticatedUserContext scoped) action,
}) async {
  if (!methods.contains(context.request.method)) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      headers: <String, String>{
        HttpHeaders.allowHeader: methods
            .map((method) => method.name.toUpperCase())
            .join(', '),
      },
    );
  }

  try {
    final scoped = context.read<AuthenticatedUserContext>();
    return await action(scoped);
  } on Exception catch (error) {
    return mapRoleScopedException(error);
  }
}

/// Parses a path ObjectId or returns a not-found response.
ObjectId? parsePathObjectId(String raw) {
  try {
    return ObjectId.fromHexString(raw);
  } catch (_) {
    return null;
  }
}

/// 404 used when an address path id is malformed or not owned.
Response addressNotFoundResponse() {
  return jsonError(
    code: 'address_not_found',
    message: 'Address was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when an admin cleaner path id is malformed or unknown.
Response cleanerApplicationNotFoundResponse() {
  return jsonError(
    code: 'cleaner_application_not_found',
    message: 'Cleaner application was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a cleaner availability path id is malformed or not owned.
Response availabilityNotFoundResponse() {
  return jsonError(
    code: 'availability_not_found',
    message: 'Availability slot was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a platform service path id is malformed or unknown.
Response serviceNotFoundResponse() {
  return jsonError(
    code: 'service_not_found',
    message: 'Service was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a customer cannot see the requested cleaner.
Response cleanerNotFoundResponse() {
  return jsonError(
    code: 'cleaner_not_found',
    message: 'Cleaner was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a booking path id is malformed or not owned.
Response bookingNotFoundResponse() {
  return jsonError(
    code: 'booking_not_found',
    message: 'Booking was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a payment path id is malformed or not owned.
Response paymentNotFoundResponse() {
  return jsonError(
    code: 'payment_not_found',
    message: 'Payment was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a conversation path id is malformed or not a member.
Response conversationNotFoundResponse() {
  return jsonError(
    code: 'conversation_not_found',
    message: 'Conversation was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a notification path id is malformed or not owned.
Response notificationNotFoundResponse() {
  return jsonError(
    code: 'notification_not_found',
    message: 'Notification was not found.',
    statusCode: HttpStatus.notFound,
  );
}

/// 404 used when a review path id is malformed or unknown.
Response reviewNotFoundResponse() {
  return jsonError(
    code: 'review_not_found',
    message: 'Review was not found.',
    statusCode: HttpStatus.notFound,
  );
}
