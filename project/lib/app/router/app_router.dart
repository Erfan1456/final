import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_form_screen.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/cleaner_approval_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/cleaner_approval_list_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/signup_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/splash_screen.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_form_screen.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_management_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_comparison_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_discovery_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_discovery_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Application router with authentication and role redirects.
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
          final role = auth.user?.role ?? 'customer';
          final home = AppRoutes.homeForRole(role);
          if (isAuthRoute ||
              isSplash ||
              isRoot ||
              location == AppRoutes.homePath) {
            return home;
          }
          if (AppRoutes.isForeignRolePath(location, role)) {
            return home;
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
        redirect: (context, state) {
          final role =
              ref.read(authControllerProvider).user?.role ?? 'customer';
          return AppRoutes.homeForRole(role);
        },
      ),
      GoRoute(
        path: AppRoutes.customerHomePath,
        name: AppRoutes.customerHomeName,
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerProfilePath,
        builder: (context, state) => const CustomerProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerAddressesPath,
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerAddressNewPath,
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerAddressEditPath,
        builder: (context, state) {
          return AddressFormScreen(
            addressId: state.pathParameters['addressId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerDiscoverPath,
        builder: (context, state) => const CleanerDiscoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerCleanerDetailPath,
        builder: (context, state) {
          return CleanerDiscoveryDetailScreen(
            cleanerUserId: state.pathParameters['cleanerUserId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerComparePath,
        builder: (context, state) => const CleanerComparisonScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerHomePath,
        name: AppRoutes.cleanerHomeName,
        builder: (context, state) => const CleanerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerOnboardingPath,
        builder: (context, state) => const CleanerOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerServicesPath,
        builder: (context, state) => const CleanerServiceManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerAvailabilityPath,
        builder: (context, state) => const CleanerAvailabilityScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerAvailabilityNewPath,
        builder: (context, state) => const CleanerAvailabilityFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerAvailabilityEditPath,
        builder: (context, state) {
          return CleanerAvailabilityFormScreen(
            slotId: state.pathParameters['slotId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminHomePath,
        name: AppRoutes.adminHomeName,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCleanersPath,
        builder: (context, state) => const CleanerApprovalListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCleanerDetailPath,
        builder: (context, state) {
          return CleanerApprovalDetailScreen(
            userId: state.pathParameters['userId'] ?? '',
          );
        },
      ),
    ],
  );
});
