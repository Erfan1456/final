import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/foundation/presentation/foundation_screen.dart';

/// Application router boundary. Authentication, role redirects, nested
/// navigation, and deep-link business behavior are deferred.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.foundationPath,
    routes: [
      GoRoute(
        path: AppRoutes.foundationPath,
        name: AppRoutes.foundationName,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
});
