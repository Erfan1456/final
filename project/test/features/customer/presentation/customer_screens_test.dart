import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('CustomerHome shows marketplace title and incomplete profile', (
    tester,
  ) async {
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
              const NotificationState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(home: CustomerHomeScreen()),
      ),
    );

    expect(find.text('Home Cleaning Service Marketplace'), findsOneWidget);
    expect(find.textContaining('person@example.com'), findsOneWidget);
    expect(find.textContaining('Complete your profile'), findsOneWidget);
    expect(find.text('No default address selected'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Addresses'), findsOneWidget);
    expect(find.text('Find a Cleaner'), findsOneWidget);
    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('CustomerHome shows profile complete and default address', (
    tester,
  ) async {
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
              CustomerProfileState(
                loading: false,
                profile: testCustomerProfile(),
              ),
            ),
          ),
          addressControllerProvider.overrideWith(
            () => SeededAddressController(
              AddressListState(
                loading: false,
                addresses: [testAddress(isDefault: true)],
              ),
            ),
          ),
          notificationControllerProvider.overrideWith(
            () => SeededNotificationController(
              const NotificationState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(home: CustomerHomeScreen()),
      ),
    );

    expect(find.text('Profile ready'), findsOneWidget);
    expect(find.textContaining('Default address: Home'), findsOneWidget);
  });

  testWidgets('CustomerProfile loads values and saves', (tester) async {
    final controller = SeededCustomerProfileController(
      CustomerProfileState(loading: false, profile: testCustomerProfile()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerProfileControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: CustomerProfileScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('+15555550100'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(controller.saveCalls, equals(1));
  });

  testWidgets('CustomerProfile shows a local validation error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerProfileControllerProvider.overrideWith(
            () => SeededCustomerProfileController(
              const CustomerProfileState(loading: false),
            ),
          ),
        ],
        child: const MaterialApp(home: CustomerProfileScreen()),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Full name must be 2–100 characters.'), findsOneWidget);
  });
}
