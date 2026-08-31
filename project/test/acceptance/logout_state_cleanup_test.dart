import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_home_screen.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';
import 'acceptance_harness.dart';

const _userAId = '507f1f77bcf86cd7994390a1';
const _userBId = '507f1f77bcf86cd7994390b2';
const _cleanerAId = '507f1f77bcf86cd7994390c1';
const _cleanerBId = '507f1f77bcf86cd7994390c2';
const _adminAId = '507f1f77bcf86cd7994390d1';
const _adminBId = '507f1f77bcf86cd7994390d2';

const _userABookingMarker = 'Ada Cleaner';
const _userAChatMarker = 'USER_A_CHAT_SECRET_MARKER';
const _userANotificationMarker = 'USER_A_NOTIFICATION_MARKER';
const _userAProfileMarker = 'USER_A_PROFILE_MARKER';
const _userAEarningsAmount = 987654321;
const _adminAMarker = 'ADMIN_A_PENDING_CLEANER_MARKER';

CustomerProfile _userAProfile() {
  final created = DateTime.utc(2026, 8, 25, 12);
  return CustomerProfile(
    id: '507f1f77bcf86cd799439021',
    userId: _userAId,
    fullName: _userAProfileMarker,
    phoneE164: '+15555550100',
    createdAt: created,
    updatedAt: created,
  );
}

/// Pumps the app once and keeps the same [ProviderScope] for auth transitions.
Future<SeededAuthController> pumpPersistentAcceptanceApp(
  WidgetTester tester, {
  required AuthUser user,
  required List<dynamic> Function() featureOverrides,
}) async {
  final auth = SeededAuthController(AuthState.authenticated(user));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        ...featureOverrides(),
      ],
      child: const HomeCleaningMarketplaceApp(),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

Future<void> logoutFromHome(WidgetTester tester) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log out'));
  await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);
}

Future<void> loginAs(
  WidgetTester tester,
  SeededAuthController auth,
  AuthUser user,
) async {
  auth.nextAuthenticatedUser = user;
  await auth.login(email: user.email, password: 'Password1!');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'same ProviderScope: logout isolates bookings/chat/notifications/profile',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userA = testUser(id: _userAId, email: 'first.customer@example.com');
      final userB = testUser(
        id: _userBId,
        email: 'second.customer@example.com',
      );

      final auth = await pumpPersistentAcceptanceApp(
        tester,
        user: userA,
        featureOverrides: () => featureControllerOverrides(
          scopedToUserId: _userAId,
          customerProfile: CustomerProfileState(
            loading: false,
            profile: _userAProfile(),
          ),
          customerBooking: CustomerBookingState(
            loading: false,
            items: [testCustomerBooking()],
          ),
          bookingChat: BookingChatState(
            loading: false,
            conversation: testConversationDetail(),
            messages: [testChatMessage(body: _userAChatMarker)],
          ),
          notifications: NotificationState(
            loading: false,
            items: [testInboxNotification(title: _userANotificationMarker)],
          ),
        ),
      );
      expect(find.byType(CustomerHomeScreen), findsOneWidget);

      final router = routerOf(tester, find.byType(CustomerHomeScreen));
      router.go(AppRoutes.customerBookingsPath);
      await tester.pumpAndSettle();
      expect(find.text(_userABookingMarker), findsOneWidget);

      router.go(
        AppRoutes.customerBookingChatLocation('507f1f77bcf86cd799439091'),
      );
      await tester.pumpAndSettle();
      expect(find.text(_userAChatMarker), findsOneWidget);

      router.go(AppRoutes.notificationsPath);
      await tester.pumpAndSettle();
      expect(find.text(_userANotificationMarker), findsOneWidget);

      router.go(AppRoutes.customerProfilePath);
      await tester.pumpAndSettle();
      expect(find.text(_userAProfileMarker), findsOneWidget);

      router.go(AppRoutes.customerHomePath);
      await tester.pumpAndSettle();
      await logoutFromHome(tester);
      expect(auth.logoutCalls, equals(1));

      // Same ProviderScope / auth controller — production logout→login path.
      await loginAs(tester, auth, userB);
      expect(find.byType(CustomerHomeScreen), findsOneWidget);
      expect(
        find.textContaining('second.customer@example.com'),
        findsOneWidget,
      );

      final secondRouter = routerOf(tester, find.byType(CustomerHomeScreen));
      secondRouter.go(AppRoutes.customerBookingsPath);
      await tester.pumpAndSettle();
      expect(find.text(_userABookingMarker), findsNothing);
      expect(find.text('No bookings yet.'), findsOneWidget);

      secondRouter.go(
        AppRoutes.customerBookingChatLocation('507f1f77bcf86cd799439091'),
      );
      await tester.pumpAndSettle();
      expect(find.text(_userAChatMarker), findsNothing);
      expect(find.text('No messages yet.'), findsOneWidget);

      secondRouter.go(AppRoutes.notificationsPath);
      await tester.pumpAndSettle();
      expect(find.text(_userANotificationMarker), findsNothing);
      expect(find.text('No notifications yet.'), findsOneWidget);

      secondRouter.go(AppRoutes.customerProfilePath);
      await tester.pumpAndSettle();
      expect(find.text(_userAProfileMarker), findsNothing);
    },
  );

  testWidgets('same ProviderScope: logout isolates cleaner earnings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cleanerA = testUser(
      id: _cleanerAId,
      email: 'first.cleaner@example.com',
      role: 'cleaner',
    );
    final cleanerB = testUser(
      id: _cleanerBId,
      email: 'second.cleaner@example.com',
      role: 'cleaner',
    );

    final auth = await pumpPersistentAcceptanceApp(
      tester,
      user: cleanerA,
      featureOverrides: () => featureControllerOverrides(
        scopedToUserId: _cleanerAId,
        cleanerOnboarding: CleanerOnboardingState(
          loading: false,
          profile: testCleanerProfile(status: OnboardingStatus.approved),
        ),
        cleanerBooking: CleanerBookingState(
          loading: false,
          items: [
            testCleanerBooking(
              customerDisplayName: '$_userAEarningsAmount Marker',
            ),
          ],
        ),
      ),
    );
    expect(find.byType(CleanerHomeScreen), findsOneWidget);

    final router = routerOf(tester, find.byType(CleanerHomeScreen));
    router.go(AppRoutes.cleanerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.textContaining('$_userAEarningsAmount'), findsWidgets);

    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    await logoutFromHome(tester);
    expect(auth.logoutCalls, equals(1));

    await loginAs(tester, auth, cleanerB);
    expect(find.byType(CleanerHomeScreen), findsOneWidget);
    routerOf(
      tester,
      find.byType(CleanerHomeScreen),
    ).go(AppRoutes.cleanerBookingsPath);
    await tester.pumpAndSettle();
    expect(find.textContaining('$_userAEarningsAmount'), findsNothing);
  });

  testWidgets('same ProviderScope: logout isolates admin operational data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adminA = testUser(
      id: _adminAId,
      email: 'admin.a@example.com',
      role: 'admin',
    );
    final adminB = testUser(
      id: _adminBId,
      email: 'admin.b@example.com',
      role: 'admin',
    );

    final auth = await pumpPersistentAcceptanceApp(
      tester,
      user: adminA,
      featureOverrides: () => featureControllerOverrides(
        scopedToUserId: _adminAId,
        adminCleanerReview: AdminCleanerReviewState(
          loading: false,
          items: [
            AdminCleanerApplicationSummary(
              id: '507f1f77bcf86cd799439041',
              userId: '507f1f77bcf86cd799439077',
              fullName: _adminAMarker,
              email: 'pending.cleaner@example.com',
              onboardingStatus: OnboardingStatus.pending,
              submittedAt: DateTime.utc(2026, 8, 25, 12),
            ),
          ],
        ),
      ),
    );
    expect(find.byType(AdminHomeScreen), findsOneWidget);

    final router = routerOf(tester, find.byType(AdminHomeScreen));
    router.go(AppRoutes.adminCleanersPath);
    await tester.pumpAndSettle();
    expect(find.text(_adminAMarker), findsOneWidget);

    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    await logoutFromHome(tester);
    expect(auth.logoutCalls, equals(1));

    await loginAs(tester, auth, adminB);
    expect(find.byType(AdminHomeScreen), findsOneWidget);
    routerOf(
      tester,
      find.byType(AdminHomeScreen),
    ).go(AppRoutes.adminCleanersPath);
    await tester.pumpAndSettle();
    expect(find.text(_adminAMarker), findsNothing);
    expect(find.text('No pending cleaner approvals.'), findsOneWidget);
  });
}
