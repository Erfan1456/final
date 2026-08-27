import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_confirmation_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_screen.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_controller.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_screen.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_screen.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';
import 'acceptance_harness.dart';

void main() {
  testWidgets('AppErrorState presents safe message and Try Again', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Unable to load cleaners. Please try again.',
            onRetry: () => retries += 1,
          ),
        ),
      ),
    );

    expect(
      find.text('Unable to load cleaners. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    expect(retries, equals(1));
  });

  testWidgets('discovery error state renders safe network message', (
    tester,
  ) async {
    await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser()),
      featureOverrides: () => featureControllerOverrides(
        discovery: const DiscoveryState(
          loading: false,
          errorMessage: 'Network unavailable. Please try again.',
        ),
      ),
    );
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    routerOf(
      tester,
      find.byType(CustomerHomeScreen),
    ).go(AppRoutes.customerDiscoverPath);
    await tester.pumpAndSettle();
    expect(find.text('Network unavailable. Please try again.'), findsOneWidget);
  });

  testWidgets('discovery empty list still shows Find Cleaners chrome', (
    tester,
  ) async {
    await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser()),
      featureOverrides: () => featureControllerOverrides(
        discovery: const DiscoveryState(loading: false),
      ),
    );
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    routerOf(
      tester,
      find.byType(CustomerHomeScreen),
    ).go(AppRoutes.customerDiscoverPath);
    await tester.pumpAndSettle();
    expect(find.text('Find Cleaners'), findsWidgets);
  });

  testWidgets('unauthenticated protected route redirects to login', (
    tester,
  ) async {
    await pumpAcceptanceApp(tester, const AuthState.unauthenticated());
    expect(find.byType(LoginScreen), findsOneWidget);

    // Deep link while unauthenticated should stay on/return to login.
    routerOf(tester, find.byType(LoginScreen)).go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    routerOf(tester, find.byType(LoginScreen)).go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('foreign role routes redirect to own home', (tester) async {
    await pumpAcceptanceApp(tester, AuthState.authenticated(testUser()));
    final router = routerOf(tester, find.byType(CustomerHomeScreen));
    router.go(AppRoutes.cleanerEarningsPath);
    await tester.pumpAndSettle();
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    router.go(AppRoutes.adminFinancePath);
    await tester.pumpAndSettle();
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
  });

  testWidgets('session invalidation redirects to login', (tester) async {
    final auth = SeededAuthController(AuthState.authenticated(testUser()));
    await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser()),
      controller: auth,
    );
    expect(find.byType(CustomerHomeScreen), findsOneWidget);

    auth.expireSession();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('email_not_verified login error shows verification guidance', (
    tester,
  ) async {
    final auth = SeededAuthController(const AuthState.unauthenticated())
      ..nextError = 'Verify your email before signing in.'
      ..nextErrorCode = 'email_not_verified';

    await pumpAcceptanceApp(
      tester,
      const AuthState.unauthenticated(),
      controller: auth,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Verify your email before signing in.'), findsOneWidget);
    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('account_unavailable login shows safe message without home', (
    tester,
  ) async {
    final auth = SeededAuthController(const AuthState.unauthenticated())
      ..nextError = messageForApiCode('account_unavailable')
      ..nextErrorCode = 'account_unavailable';

    await pumpAcceptanceApp(
      tester,
      const AuthState.unauthenticated(),
      controller: auth,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('This account is currently unavailable.'), findsOneWidget);
    expect(find.byType(CustomerHomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('booking conflict error is user-visible on confirmation', (
    tester,
  ) async {
    await pumpAcceptanceScreen(
      tester,
      const BookingConfirmationScreen(
        cleanerUserId: '507f1f77bcf86cd799439081',
        slotId: '507f1f77bcf86cd799439071',
      ),
      overrides: featureControllerOverrides(
        discovery: DiscoveryState(
          loading: false,
          detail: testDiscoveryDetail(),
        ),
        addresses: AddressListState(
          loading: false,
          addresses: [testAddress(isDefault: true)],
        ),
        customerBooking: CustomerBookingState(
          loading: false,
          errorMessage: messageForApiCode('availability_unavailable'),
        ),
      ),
    );
    // beginSubmitAttempt clears errors; re-assert after restoring seed error.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookingConfirmationScreen)),
    );
    container
        .read(customerBookingControllerProvider.notifier)
        .state = CustomerBookingState(
      loading: false,
      errorMessage: messageForApiCode('availability_unavailable'),
    );
    await tester.pump();
    expect(find.text('That time slot is no longer available.'), findsOneWidget);
  });

  testWidgets('payment failure status is visible on payment screen', (
    tester,
  ) async {
    await pumpAcceptanceScreen(
      tester,
      const CustomerPaymentScreen(bookingId: '507f1f77bcf86cd799439091'),
      overrides: featureControllerOverrides(
        customerBooking: CustomerBookingState(
          loading: false,
          detail: testCustomerBooking(),
        ),
        customerPayment: CustomerPaymentState(
          loading: false,
          history: PaymentHistory(
            current: testPaymentAttempt(status: 'failed'),
            attempts: [testPaymentAttempt(status: 'failed')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Failed'), findsWidgets);
  });

  testWidgets('insufficient payout balance error is visible', (tester) async {
    await pumpAcceptanceScreen(
      tester,
      const CleanerPayoutRequestScreen(),
      overrides: featureControllerOverrides(
        cleanerEarnings: CleanerEarningsState(
          loading: false,
          errorMessage: messageForApiCode('insufficient_payout_balance'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        RegExp(r'insufficient|balance', caseSensitive: false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dispute_not_allowed error is visible on dispute screen', (
    tester,
  ) async {
    await pumpAcceptanceScreen(
      tester,
      const BookingDisputeScreen(bookingId: '507f1f77bcf86cd799439091'),
      overrides: featureControllerOverrides(
        bookingDispute: BookingDisputeState(
          loading: false,
          errorMessage: messageForApiCode('dispute_not_allowed'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('dispute'), findsWidgets);
  });

  testWidgets('current session revoke redirects to login via expireSession', (
    tester,
  ) async {
    // expireSession mirrors clearAuthenticatedSession after revokeAll /
    // current-session revoke.
    final auth = SeededAuthController(AuthState.authenticated(testUser()));
    await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser()),
      controller: auth,
    );
    expect(find.byType(CustomerHomeScreen), findsOneWidget);

    auth.clearAuthenticatedSession();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
