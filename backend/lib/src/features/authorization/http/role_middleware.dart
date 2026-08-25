import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/application/role_scoped_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
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
      var next = context.provide<AuthenticatedUserContext>(() => scoped);
      switch (requiredRole) {
        case UserRole.customer:
          final service =
              _tryRead<CustomerAccountService>(context) ??
              await RoleScopedComposition.customer(mongo: mongo!);
          next = next.provide<CustomerAccountService>(() => service);
        case UserRole.cleaner:
          final service =
              _tryRead<CleanerOnboardingService>(context) ??
              await RoleScopedComposition.cleaner(mongo: mongo!);
          next = next.provide<CleanerOnboardingService>(() => service);
        case UserRole.admin:
          final service =
              _tryRead<AdminCleanerReviewService>(context) ??
              await RoleScopedComposition.admin(mongo: mongo!);
          next = next.provide<AdminCleanerReviewService>(() => service);
      }
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
