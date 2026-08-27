import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';
import 'acceptance_harness.dart';

void main() {
  testWidgets('admin login from unauthenticated reaches admin home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = SeededAuthController(const AuthState.unauthenticated())
      ..nextAuthenticatedUser = testUser(role: 'admin');
    await pumpAcceptanceApp(
      tester,
      const AuthState.unauthenticated(),
      controller: auth,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'admin@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(auth.loginCalls, equals(1));
    expect(find.byType(AdminHomeScreen), findsOneWidget);
  });

  testWidgets('admin journey covers dashboard, ops routes, and logout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser(role: 'admin')),
      featureOverrides: () => featureControllerOverrides(
        adminPayment: AdminPaymentState(
          loading: false,
          detail: testAdminPaymentDetail(status: 'paid'),
        ),
      ),
    );

    expect(find.byType(AdminHomeScreen), findsOneWidget);
    expect(find.text('Admin Home'), findsOneWidget);
    expect(find.textContaining('person@example.com'), findsOneWidget);
    expect(find.text('Approvals'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Payouts'), findsOneWidget);
    expect(find.text('Disputes'), findsOneWidget);
    expect(find.text('Review Moderation'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);

    final router = routerOf(tester, find.byType(AdminHomeScreen));

    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(AdminHomeScreen), findsOneWidget);
    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(AdminHomeScreen), findsOneWidget);

    router.go(AppRoutes.adminCleanersPath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner approvals'), findsWidgets);

    router.go(AppRoutes.adminUsersPath);
    await tester.pumpAndSettle();
    expect(find.text('Users'), findsWidgets);

    router.go(AppRoutes.adminBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Bookings'), findsWidgets);

    router.go(AppRoutes.adminPaymentsPath);
    await tester.pumpAndSettle();
    expect(find.text('Payments'), findsWidgets);

    router.go(AppRoutes.adminPaymentDetailLocation('507f1f77bcf86cd7994390c1'));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'[Pp]ayment')), findsWidgets);
    expect(find.text('Refund'), findsOneWidget);

    router.go(AppRoutes.adminDisputesPath);
    await tester.pumpAndSettle();
    expect(find.text('Disputes'), findsWidgets);

    router.go(AppRoutes.adminReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('Review Moderation'), findsWidgets);

    router.go(AppRoutes.adminPayoutsPath);
    await tester.pumpAndSettle();
    expect(find.text('Payouts'), findsWidgets);

    router.go(AppRoutes.adminFinancePath);
    await tester.pumpAndSettle();
    expect(find.text('Finance'), findsWidgets);

    router.go(AppRoutes.adminFinanceReconciliationPath);
    await tester.pumpAndSettle();
    expect(find.text('Reconciliation'), findsWidgets);

    router.go(AppRoutes.adminAuditLogsPath);
    await tester.pumpAndSettle();
    expect(find.text('Audit Log'), findsWidgets);

    router.go(AppRoutes.notificationsPath);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);

    router.go(AppRoutes.accountSecurityPath);
    await tester.pumpAndSettle();
    expect(find.text('Account security'), findsWidgets);

    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, equals(1));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
