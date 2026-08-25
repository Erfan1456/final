import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/application/role_scoped_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/application/cleaner_availability_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/cleaner_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/application/cleaner_service_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/application/cleaner_discovery_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/admin_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/customer_payment_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/admin_review_moderation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/customer_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// Shared role middleware: Bearer auth → persisted user → current role.
Handler roleScopedMiddleware(
  Handler handler, {
  required UserRole requiredRole,
}) {
  return (context) async {
    try {
      final authorizer = await RoleScopedComposition.authorizer(context);
      final scoped = await authorizer.authorize(
        authorizationHeader:
            context.request.headers[HttpHeaders.authorizationHeader],
        requiredRole: requiredRole,
      );
      final mongo = _tryRead<MongoDatabase>(context);
      final config = _tryRead<ServerConfig>(context);
      var next = context.provide<AuthenticatedUserContext>(() => scoped);
      switch (requiredRole) {
        case UserRole.customer:
          final service =
              _tryRead<CustomerAccountService>(context) ??
              await RoleScopedComposition.customer(mongo: mongo!);
          final discovery =
              _tryRead<CleanerDiscoveryService>(context) ??
              await RoleScopedComposition.discovery(mongo: mongo!);
          final bookings =
              _tryRead<CustomerBookingService>(context) ??
              await RoleScopedComposition.customerBookings(
                mongo: mongo!,
                config: config!,
              );
          final payments =
              _tryRead<CustomerPaymentService>(context) ??
              await RoleScopedComposition.customerPayments(
                mongo: mongo!,
                config: config!,
              );
          final reviews =
              _tryRead<CustomerReviewService>(context) ??
              await RoleScopedComposition.customerReviews(mongo: mongo!);
          next = next
              .provide<CustomerAccountService>(() => service)
              .provide<CleanerDiscoveryService>(() => discovery)
              .provide<CustomerBookingService>(() => bookings)
              .provide<CustomerPaymentService>(() => payments)
              .provide<CustomerReviewService>(() => reviews);
        case UserRole.cleaner:
          final onboarding =
              _tryRead<CleanerOnboardingService>(context) ??
              await RoleScopedComposition.cleaner(mongo: mongo!);
          final offerings =
              _tryRead<CleanerServiceManagementService>(context) ??
              await RoleScopedComposition.cleanerServices(mongo: mongo!);
          final availability =
              _tryRead<CleanerAvailabilityService>(context) ??
              await RoleScopedComposition.cleanerAvailability(mongo: mongo!);
          final bookings =
              _tryRead<CleanerBookingService>(context) ??
              await RoleScopedComposition.cleanerBookings(
                mongo: mongo!,
                config: config!,
              );
          final reviews =
              _tryRead<CleanerReviewService>(context) ??
              await RoleScopedComposition.cleanerReviews(mongo: mongo!);
          next = next
              .provide<CleanerOnboardingService>(() => onboarding)
              .provide<CleanerServiceManagementService>(() => offerings)
              .provide<CleanerAvailabilityService>(() => availability)
              .provide<CleanerBookingService>(() => bookings)
              .provide<CleanerReviewService>(() => reviews);
        case UserRole.admin:
          final service =
              _tryRead<AdminCleanerReviewService>(context) ??
              await RoleScopedComposition.admin(mongo: mongo!);
          final payments =
              _tryRead<AdminPaymentService>(context) ??
              await RoleScopedComposition.adminPayments(
                mongo: mongo!,
                config: config!,
              );
          final reviews =
              _tryRead<AdminReviewModerationService>(context) ??
              await RoleScopedComposition.adminReviews(mongo: mongo!);
          next = next
              .provide<AdminCleanerReviewService>(() => service)
              .provide<AdminPaymentService>(() => payments)
              .provide<AdminReviewModerationService>(() => reviews);
      }
      return await handler(next);
    } on Exception catch (error) {
      return mapRoleScopedException(error);
    }
  };
}

/// JWT + persisted active user for routes shared by multiple roles.
Handler multiRoleMiddleware(
  Handler handler, {
  required Set<UserRole> allowedRoles,
}) {
  return (context) async {
    try {
      final authorizer = await RoleScopedComposition.authorizer(context);
      final scoped = await authorizer.authorizeAny(
        authorizationHeader:
            context.request.headers[HttpHeaders.authorizationHeader],
        allowedRoles: allowedRoles,
      );
      final mongo = _tryRead<MongoDatabase>(context);
      var next = context.provide<AuthenticatedUserContext>(() => scoped);
      if (allowedRoles.contains(UserRole.customer) ||
          allowedRoles.contains(UserRole.cleaner)) {
        final conversations =
            _tryRead<BookingConversationService>(context) ??
            await RoleScopedComposition.conversations(mongo: mongo!);
        next = next.provide<BookingConversationService>(() => conversations);
      }
      final notifications =
          _tryRead<NotificationService>(context) ??
          await RoleScopedComposition.notifications(mongo: mongo!);
      next = next.provide<NotificationService>(() => notifications);
      return await handler(next);
    } on Exception catch (error) {
      return mapRoleScopedException(error);
    }
  };
}

T? _tryRead<T>(RequestContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}
