import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_form_screen.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_list_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/cleaner_approval_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/cleaner_approval_list_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_list_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/signup_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/splash_screen.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_form_screen.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_confirmation_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_list_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_list_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_management_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_comparison_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_discovery_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_discovery_screen.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_center_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_list_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/cleaner_reviews_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_list_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_screen.dart';

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
        path: AppRoutes.customerBookSlotPath,
        builder: (context, state) {
          return BookingConfirmationScreen(
            cleanerUserId: state.pathParameters['cleanerUserId'] ?? '',
            slotId: state.pathParameters['slotId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerBookingsPath,
        builder: (context, state) => const CustomerBookingListScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerBookingDetailPath,
        builder: (context, state) {
          return CustomerBookingDetailScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerBookingPaymentPath,
        builder: (context, state) {
          return CustomerPaymentScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerBookingChatPath,
        builder: (context, state) {
          return BookingChatScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerBookingReviewPath,
        builder: (context, state) {
          return CustomerReviewScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerBookingDisputePath,
        builder: (context, state) {
          return BookingDisputeScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notificationsPath,
        builder: (context, state) => const NotificationCenterScreen(),
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
        path: AppRoutes.cleanerBookingsPath,
        builder: (context, state) => const CleanerBookingListScreen(),
      ),
      GoRoute(
        path: AppRoutes.cleanerBookingDetailPath,
        builder: (context, state) {
          return CleanerBookingDetailScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cleanerBookingChatPath,
        builder: (context, state) {
          return BookingChatScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cleanerBookingDisputePath,
        builder: (context, state) {
          return BookingDisputeScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cleanerReviewsPath,
        builder: (context, state) => const CleanerReviewsScreen(),
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
      GoRoute(
        path: AppRoutes.adminPaymentsPath,
        builder: (context, state) => const AdminPaymentListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPaymentDetailPath,
        builder: (context, state) {
          return AdminPaymentDetailScreen(
            paymentId: state.pathParameters['paymentId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminReviewsPath,
        builder: (context, state) => const AdminReviewListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReviewDetailPath,
        builder: (context, state) {
          return AdminReviewDetailScreen(
            reviewId: state.pathParameters['reviewId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminDisputesPath,
        builder: (context, state) => const AdminDisputeListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDisputeDetailPath,
        builder: (context, state) {
          return AdminDisputeDetailScreen(
            disputeId: state.pathParameters['disputeId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminUsersPath,
        builder: (context, state) => const AdminUserListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUserDetailPath,
        builder: (context, state) {
          return AdminUserDetailScreen(
            userId: state.pathParameters['userId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminBookingsPath,
        builder: (context, state) => const AdminBookingListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminBookingDetailPath,
        builder: (context, state) {
          return AdminBookingDetailScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminAuditLogsPath,
        builder: (context, state) => const AdminAuditListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAuditLogDetailPath,
        builder: (context, state) {
          return AdminAuditDetailScreen(
            auditLogId: state.pathParameters['auditLogId'] ?? '',
          );
        },
      ),
    ],
  );
});
