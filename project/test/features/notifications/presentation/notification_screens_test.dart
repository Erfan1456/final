import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_center_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('home shows unread notification count', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(AuthState.authenticated(testUser())),
          ),
          customerProfileControllerProvider.overrideWith(
            () => SeededCustomerProfileController(
              const CustomerProfileState(loading: false),
            ),
          ),
          addressControllerProvider.overrideWith(
            () =>
                SeededAddressController(const AddressListState(loading: false)),
          ),
          notificationControllerProvider.overrideWith(
            () => SeededNotificationController(
              const NotificationState(loading: false, unreadCount: 3),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.customerHomePath,
            routes: [
              GoRoute(
                path: AppRoutes.customerHomePath,
                builder: (context, state) => const CustomerHomeScreen(),
              ),
              GoRoute(
                path: AppRoutes.notificationsPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Notification center')),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Notifications (3)'), findsOneWidget);
    await tester.ensureVisible(find.text('Notifications (3)'));
    await tester.tap(find.text('Notifications (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Notification center'), findsOneWidget);
  });

  testWidgets('list shows items, mark all, and load more', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SeededNotificationController(
      NotificationState(
        loading: false,
        items: [
          testInboxNotification(),
          testInboxNotification(
            id: '2',
            title: 'Job started',
            readAt: '2026-08-25T12:30:00.000Z',
          ),
        ],
        nextCursor: 'next',
        unreadCount: 1,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('Job started'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.text('Load More'), findsOneWidget);
    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    expect(controller.markAllCalls, equals(1));
    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(controller.loadMoreCalls, equals(1));
  });

  testWidgets('tapping a known booking resource navigates', (tester) async {
    final controller = SeededNotificationController(
      NotificationState(loading: false, items: [testInboxNotification()]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(AuthState.authenticated(testUser())),
          ),
          notificationControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.notificationsPath,
            routes: [
              GoRoute(
                path: AppRoutes.notificationsPath,
                builder: (context, state) => const NotificationCenterScreen(),
              ),
              GoRoute(
                path: AppRoutes.customerBookingDetailPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Booking detail route')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Booking confirmed'));
    await tester.pumpAndSettle();
    expect(controller.markOneCalls, equals(1));
    expect(find.text('Booking detail route'), findsOneWidget);
  });

  testWidgets('unknown resource marks read and stays on center', (
    tester,
  ) async {
    final controller = SeededNotificationController(
      NotificationState(
        loading: false,
        items: [
          testInboxNotification(
            title: 'Mystery',
            resourceType: 'secret_url',
            resourceId: 'https://evil.example/steal',
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(AuthState.authenticated(testUser())),
          ),
          notificationControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mystery'));
    await tester.pumpAndSettle();
    expect(controller.markOneCalls, equals(1));
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Mystery'), findsOneWidget);
  });
}
