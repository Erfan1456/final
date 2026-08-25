import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/authenticated_home_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/signup_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/splash_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Application router with authentication redirects.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (!identical(previous, next)) {
      refresh.ping();
    }
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splashPath;
      final isAuthRoute =
          location == AppRoutes.loginPath || location == AppRoutes.signupPath;
      final isRoot = location == '/';

      switch (auth.status) {
        case AuthStatus.restoring:
          return isSplash ? null : AppRoutes.splashPath;
        case AuthStatus.unauthenticated:
          if (isAuthRoute) {
            return null;
          }
          return AppRoutes.loginPath;
        case AuthStatus.authenticated:
          if (isAuthRoute || isSplash || isRoot) {
            return AppRoutes.homePath;
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.splashPath),
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupPath,
        name: AppRoutes.signupName,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const AuthenticatedHomeScreen(),
      ),
    ],
  );
});
