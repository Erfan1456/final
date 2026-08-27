import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';

import '../../helpers/auth_test_fakes.dart';
import '../../helpers/feature_test_fakes.dart';

Future<void> pumpApp(
  WidgetTester tester,
  AuthState state, {
  bool settle = true,
  SeededAuthController? controller,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => controller ?? SeededAuthController(state),
        ),
        ...featureControllerOverrides(),
      ],
      child: const HomeCleaningMarketplaceApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('restoring shows splash', (tester) async {
    await pumpApp(tester, const AuthState.restoring(), settle: false);
    expect(find.text('Restoring session...'), findsOneWidget);
  });

  testWidgets('unauthenticated shows login', (tester) async {
    await pumpApp(tester, const AuthState.unauthenticated());
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('unauthenticated can open signup', (tester) async {
    await pumpApp(tester, const AuthState.unauthenticated());
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Customer'), findsOneWidget);
  });

  testWidgets('customer session reaches customer home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    expect(find.text('Home Cleaning Service Marketplace'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('Manage Profile'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
  });

  testWidgets('authenticated customer cannot remain on login', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('cleaner session reaches cleaner home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    expect(find.text('Cleaner home'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
  });

  testWidgets('admin session reaches admin home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Cleaner Approvals'), findsOneWidget);
  });

  testWidgets('/home redirects a customer to customer home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(context).go(AppRoutes.homePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('customer cannot remain on cleaner or admin routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner cannot remain on customer or admin routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('admin cannot remain on customer or cleaner routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('logout redirects to login', (tester) async {
    final controller = SeededAuthController(
      AuthState.authenticated(testUser()),
    );
    await pumpApp(
      tester,
      AuthState.authenticated(testUser()),
      controller: controller,
    );
    await controller.logout();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('session expiry redirects to login', (tester) async {
    final controller = SeededAuthController(
      AuthState.authenticated(testUser()),
    );
    await pumpApp(
      tester,
      AuthState.authenticated(testUser()),
      controller: controller,
    );
    controller.expireSession();
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('customer can open discovery, detail, and compare', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(AppRoutes.customerDiscoverPath);
    await tester.pumpAndSettle();
    expect(find.text('Find Cleaners'), findsWidgets);
    router.go(
      AppRoutes.customerCleanerDetailPath.replaceFirst(
        ':cleanerUserId',
        '507f1f77bcf86cd799439081',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cleaner details'), findsOneWidget);
    router.go(AppRoutes.customerComparePath);
    await tester.pumpAndSettle();
    expect(find.text('Compare cleaners'), findsOneWidget);
  });

  testWidgets('customer can open booking confirmation, list, and detail', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(
      AppRoutes.customerBookSlotLocation(
        '507f1f77bcf86cd799439081',
        '507f1f77bcf86cd799439071',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirm booking'), findsOneWidget);
    router.go(AppRoutes.customerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('My Bookings'), findsWidgets);
    router.go(
      AppRoutes.customerBookingDetailLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Booking details'), findsOneWidget);
    router.go(
      AppRoutes.customerBookingPaymentLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsWidgets);
  });

  testWidgets('customer can open shared notifications', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(context).go(AppRoutes.notificationsPath);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('cleaner can open shared notifications', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    GoRouter.of(context).go(AppRoutes.notificationsPath);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('admin can open shared notifications', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    GoRouter.of(context).go(AppRoutes.notificationsPath);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('customer can open booking chat and review', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(
      AppRoutes.customerBookingChatLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chat'), findsWidgets);
    router.go(
      AppRoutes.customerBookingReviewLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsWidgets);
    router.go(
      AppRoutes.customerBookingDisputeLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dispute'), findsWidgets);
  });

  testWidgets('cleaner can open booking chat and my reviews', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerBookingChatLocation('507f1f77bcf86cd799439091'));
    await tester.pumpAndSettle();
    expect(find.text('Chat'), findsWidgets);
    router.go(AppRoutes.cleanerReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('My Reviews'), findsWidgets);
    router.go(
      AppRoutes.cleanerBookingDisputeLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dispute'), findsWidgets);
  });

  testWidgets('admin can open review moderation', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.adminReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('Review Moderation'), findsWidgets);
    router.go(AppRoutes.adminReviewDetailLocation('507f1f77bcf86cd7994390e1'));
    await tester.pumpAndSettle();
    expect(find.text('Review moderation'), findsOneWidget);
    router.go(AppRoutes.adminDisputesPath);
    await tester.pumpAndSettle();
    expect(find.text('Disputes'), findsWidgets);
    router.go(AppRoutes.adminUsersPath);
    await tester.pumpAndSettle();
    expect(find.text('Users'), findsWidgets);
    router.go(AppRoutes.adminBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Bookings'), findsWidgets);
    router.go(AppRoutes.adminAuditLogsPath);
    await tester.pumpAndSettle();
    expect(find.text('Audit Log'), findsWidgets);
  });

  testWidgets('customer is redirected from cleaner chat and admin reviews', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerBookingChatLocation('507f1f77bcf86cd799439091'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
    router.go(AppRoutes.adminReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
    router.go(AppRoutes.adminDisputesPath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
    router.go(
      AppRoutes.cleanerBookingDisputeLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner is redirected from customer chat and admin reviews', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(
      AppRoutes.customerBookingChatLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
    router.go(AppRoutes.adminReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
    router.go(AppRoutes.adminUsersPath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
    router.go(
      AppRoutes.customerBookingDisputeLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('admin is redirected from customer chat and cleaner reviews', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(
      AppRoutes.customerBookingChatLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
    router.go(AppRoutes.cleanerReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
    router.go(
      AppRoutes.customerBookingDisputeLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('cleaner can open booking list and detail', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Booking Requests / Jobs'), findsWidgets);
    router.go(
      AppRoutes.cleanerBookingDetailLocation('507f1f77bcf86cd799439091'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Job details'), findsOneWidget);
  });

  testWidgets('customer is redirected from cleaner booking routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final customerContext = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(customerContext).go(AppRoutes.cleanerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner is redirected from customer booking routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final cleanerContext = tester.element(find.text('Cleaner home'));
    GoRouter.of(cleanerContext).go(AppRoutes.customerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('admin is redirected from customer and cleaner booking routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final adminContext = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(adminContext);
    router.go(AppRoutes.customerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
    router.go(AppRoutes.cleanerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('cleaner can open services and availability', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerServicesPath);
    await tester.pumpAndSettle();
    expect(find.text('Approval required'), findsOneWidget);
    router.go(AppRoutes.cleanerAvailabilityPath);
    await tester.pumpAndSettle();
    expect(find.text('Approval required'), findsOneWidget);
  });

  testWidgets('customer trying a cleaner management route is redirected', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(context).go(AppRoutes.cleanerServicesPath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner trying customer discovery is redirected', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    GoRouter.of(context).go(AppRoutes.customerDiscoverPath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('admin cannot remain on customer discovery or cleaner services', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.customerDiscoverPath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
    router.go(AppRoutes.cleanerAvailabilityPath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('admin can open payment list and detail', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.adminPaymentsPath);
    await tester.pumpAndSettle();
    expect(find.text('Payments'), findsWidgets);
    router.go(AppRoutes.adminPaymentDetailLocation('507f1f77bcf86cd7994390d1'));
    await tester.pumpAndSettle();
    expect(find.text('Payment transaction'), findsOneWidget);
  });

  testWidgets('customer cannot remain on admin payment routes', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(context).go(AppRoutes.adminPaymentsPath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner cannot remain on customer payment routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final cleanerContext = tester.element(find.text('Cleaner home'));
    GoRouter.of(
      cleanerContext,
    ).go(AppRoutes.customerBookingPaymentLocation('507f1f77bcf86cd799439091'));
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('admin cannot remain on customer payment routes', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final adminContext = tester.element(find.text('Admin Dashboard'));
    GoRouter.of(
      adminContext,
    ).go(AppRoutes.customerBookingPaymentLocation('507f1f77bcf86cd799439091'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('cleaner can open earnings and payout routes', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerEarningsPath);
    await tester.pumpAndSettle();
    expect(find.text('Earnings & Payouts'), findsWidgets);
    router.go(AppRoutes.cleanerEarningsLedgerPath);
    await tester.pumpAndSettle();
    expect(find.text('Earnings ledger'), findsWidgets);
    router.go(AppRoutes.cleanerPayoutsPath);
    await tester.pumpAndSettle();
    expect(find.text('Payout history'), findsWidgets);
    router.go(AppRoutes.cleanerPayoutRequestPath);
    await tester.pumpAndSettle();
    expect(find.text('Request payout'), findsWidgets);
  });

  testWidgets('customer is redirected from cleaner finance routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(context).go(AppRoutes.cleanerEarningsPath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('admin can open payouts, finance, and reconciliation', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.adminPayoutsPath);
    await tester.pumpAndSettle();
    expect(find.text('Payouts'), findsWidgets);
    router.go(AppRoutes.adminPayoutDetailLocation('507f1f77bcf86cd7994390f1'));
    await tester.pumpAndSettle();
    expect(find.text('Payout detail'), findsOneWidget);
    router.go(AppRoutes.adminFinancePath);
    await tester.pumpAndSettle();
    expect(find.text('Finance'), findsWidgets);
    router.go(AppRoutes.adminFinanceReconciliationPath);
    await tester.pumpAndSettle();
    expect(find.text('Reconciliation'), findsWidgets);
    router.go(AppRoutes.adminUserFinanceLocation('507f1f77bcf86cd799439022'));
    await tester.pumpAndSettle();
    expect(find.text('Cleaner finance'), findsOneWidget);
  });

  testWidgets('customer cannot remain on admin finance routes', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final customerContext = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(customerContext).go(AppRoutes.adminFinancePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner cannot remain on admin payout routes', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final cleanerContext = tester.element(find.text('Cleaner home'));
    GoRouter.of(cleanerContext).go(AppRoutes.adminPayoutsPath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('unauthenticated can open forgot password', (tester) async {
    await pumpApp(tester, const AuthState.unauthenticated());
    final context = tester.element(find.byType(LoginScreen));
    GoRouter.of(context).go(AppRoutes.forgotPasswordPath);
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('authenticated customer can open account security', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(AppRoutes.accountSecurityPath);
    await tester.pumpAndSettle();
    expect(find.text('Account security'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    router.go(AppRoutes.accountChangePasswordPath);
    await tester.pumpAndSettle();
    expect(find.text('Change password'), findsWidgets);
  });

  testWidgets('admin is redirected from cleaner payout-request routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    GoRouter.of(context).go(AppRoutes.cleanerPayoutRequestPath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });
}
