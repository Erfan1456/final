import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';
import 'acceptance_harness.dart';

const _bookingId = '507f1f77bcf86cd799439091';

void main() {
  testWidgets('cleaner login from unauthenticated reaches cleaner home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = SeededAuthController(const AuthState.unauthenticated())
      ..nextAuthenticatedUser = testUser(role: 'cleaner');
    await pumpAcceptanceApp(
      tester,
      const AuthState.unauthenticated(),
      controller: auth,
      featureOverrides: () => featureControllerOverrides(
        cleanerOnboarding: CleanerOnboardingState(
          loading: false,
          profile: testCleanerProfile(status: OnboardingStatus.approved),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'cleaner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(auth.loginCalls, equals(1));
    expect(find.byType(CleanerHomeScreen), findsOneWidget);
  });

  testWidgets('cleaner journey covers home, workflows, earnings, logout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser(role: 'cleaner')),
      featureOverrides: () => featureControllerOverrides(
        cleanerOnboarding: CleanerOnboardingState(
          loading: false,
          profile: testCleanerProfile(status: OnboardingStatus.approved),
        ),
        cleanerBooking: CleanerBookingState(
          loading: false,
          detail: testCleanerBooking(status: BookingStatus.pending),
        ),
      ),
    );
    expect(auth, isNotNull);

    expect(find.byType(CleanerHomeScreen), findsOneWidget);
    expect(find.text('Cleaner Home'), findsOneWidget);
    expect(find.textContaining('person@example.com'), findsOneWidget);
    expect(find.text('Dashboard / Booking Requests'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Earnings & Payouts'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);

    final router = routerOf(tester, find.byType(CleanerHomeScreen));

    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(CleanerHomeScreen), findsOneWidget);
    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.byType(CleanerHomeScreen), findsOneWidget);

    router.go(AppRoutes.cleanerOnboardingPath);
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'[Oo]nboarding')), findsWidgets);

    router.go(AppRoutes.cleanerServicesPath);
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'[Ss]ervice')), findsWidgets);

    router.go(AppRoutes.cleanerAvailabilityPath);
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'[Aa]vailability')), findsWidgets);

    router.go(AppRoutes.cleanerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.text('Booking Requests / Jobs'), findsWidgets);

    router.go(AppRoutes.cleanerBookingDetailLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Job details'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);

    // Action buttons for confirmed / in-progress via re-seeded detail screens.
    await pumpAcceptanceScreen(
      tester,
      const CleanerBookingDetailScreen(bookingId: _bookingId),
      overrides: [
        cleanerBookingControllerProvider.overrideWith(
          () => SeededCleanerBookingController(
            CleanerBookingState(
              loading: false,
              detail: testCleanerBooking(
                status: BookingStatus.confirmed,
                startAt: '2026-08-01T03:00:00.000Z',
                endAt: '2026-12-01T05:00:00.000Z',
              ),
            ),
          ),
        ),
        bookingDisputeControllerProvider.overrideWith(
          () => SeededBookingDisputeController(
            const BookingDisputeState(loading: false),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Start Job'), findsOneWidget);

    await pumpAcceptanceScreen(
      tester,
      const CleanerBookingDetailScreen(bookingId: _bookingId),
      overrides: [
        cleanerBookingControllerProvider.overrideWith(
          () => SeededCleanerBookingController(
            CleanerBookingState(
              loading: false,
              detail: testCleanerBooking(status: BookingStatus.inProgress),
            ),
          ),
        ),
        bookingDisputeControllerProvider.overrideWith(
          () => SeededBookingDisputeController(
            const BookingDisputeState(loading: false),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Complete Job'), findsOneWidget);

    // Resume full-app journey for remaining routes.
    await pumpAcceptanceApp(
      tester,
      AuthState.authenticated(testUser(role: 'cleaner')),
      controller: SeededAuthController(
        AuthState.authenticated(testUser(role: 'cleaner')),
      ),
      featureOverrides: () => featureControllerOverrides(
        cleanerOnboarding: CleanerOnboardingState(
          loading: false,
          profile: testCleanerProfile(status: OnboardingStatus.approved),
        ),
      ),
    );
    final resume = routerOf(tester, find.byType(CleanerHomeScreen));

    resume.go(AppRoutes.cleanerBookingChatLocation(_bookingId));
    await tester.pumpAndSettle();
    expect(find.text('Chat'), findsWidgets);

    resume.go(AppRoutes.cleanerEarningsPath);
    await tester.pumpAndSettle();
    expect(find.text('Earnings & Payouts'), findsWidgets);

    resume.go(AppRoutes.cleanerPayoutRequestPath);
    await tester.pumpAndSettle();
    expect(find.text('Request payout'), findsWidgets);
    expect(find.textContaining('Development Sandbox'), findsOneWidget);

    resume.go(AppRoutes.cleanerPayoutsPath);
    await tester.pumpAndSettle();
    expect(find.text('Payout history'), findsWidgets);

    resume.go(AppRoutes.cleanerReviewsPath);
    await tester.pumpAndSettle();
    expect(find.text('My Reviews'), findsWidgets);

    resume.go(AppRoutes.notificationsPath);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);

    resume.go(AppRoutes.accountSecurityPath);
    await tester.pumpAndSettle();
    expect(find.text('Account security'), findsWidgets);

    resume.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log out'));
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
