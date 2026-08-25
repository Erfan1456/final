import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/availability_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_form_screen.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/catalog/presentation/catalog_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

List<dynamic> availabilityOverrides({
  required CleanerOnboardingState onboarding,
  AvailabilityState? availability,
  SeededAvailabilityController? controller,
}) {
  return [
    cleanerOnboardingControllerProvider.overrideWith(
      () => SeededCleanerOnboardingController(onboarding),
    ),
    catalogControllerProvider.overrideWith(
      () => SeededCatalogController(
        CatalogState(loading: false, items: [testMarketplaceService()]),
      ),
    ),
    availabilityControllerProvider.overrideWith(
      () =>
          controller ??
          SeededAvailabilityController(
            availability ?? const AvailabilityState(loading: false),
          ),
    ),
  ];
}

void main() {
  testWidgets('unapproved availability shows approval required', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...availabilityOverrides(
            onboarding: CleanerOnboardingState(
              loading: false,
              profile: testCleanerProfile(),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerAvailabilityScreen()),
      ),
    );
    expect(find.text('Approval required'), findsOneWidget);
  });

  testWidgets('slot list renders local time, duration, and actions', (
    tester,
  ) async {
    final slot = testAvailabilitySlot();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...availabilityOverrides(
            onboarding: CleanerOnboardingState(
              loading: false,
              profile: testCleanerProfile(status: OnboardingStatus.approved),
            ),
            availability: AvailabilityState(loading: false, slots: [slot]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.cleanerAvailabilityPath,
            routes: [
              GoRoute(
                path: AppRoutes.cleanerAvailabilityPath,
                builder: (context, state) => const CleanerAvailabilityScreen(),
              ),
              GoRoute(
                path: AppRoutes.cleanerAvailabilityNewPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Add Availability form')),
              ),
              GoRoute(
                path: AppRoutes.cleanerAvailabilityEditPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Edit Availability form')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.textContaining('120 min'), findsOneWidget);
    expect(
      find.textContaining(formatLocalDateTime(slot.startAt)),
      findsOneWidget,
    );
    expect(find.text('Add Availability'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.tap(find.text('Add Availability'));
    await tester.pumpAndSettle();
    expect(find.text('Add Availability form'), findsOneWidget);
  });

  testWidgets('edit navigation opens the form route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...availabilityOverrides(
            onboarding: CleanerOnboardingState(
              loading: false,
              profile: testCleanerProfile(status: OnboardingStatus.approved),
            ),
            availability: AvailabilityState(
              loading: false,
              slots: [testAvailabilitySlot()],
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.cleanerAvailabilityPath,
            routes: [
              GoRoute(
                path: AppRoutes.cleanerAvailabilityPath,
                builder: (context, state) => const CleanerAvailabilityScreen(),
              ),
              GoRoute(
                path: AppRoutes.cleanerAvailabilityEditPath,
                builder: (context, state) => Scaffold(
                  body: Text('edit:${state.pathParameters['slotId']}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('edit:507f1f77bcf86cd799439071'), findsOneWidget);
  });

  testWidgets('delete requires confirmation', (tester) async {
    final controller = SeededAvailabilityController(
      AvailabilityState(loading: false, slots: [testAvailabilitySlot()]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...availabilityOverrides(
            onboarding: CleanerOnboardingState(
              loading: false,
              profile: testCleanerProfile(status: OnboardingStatus.approved),
            ),
            controller: controller,
          ),
        ],
        child: const MaterialApp(home: CleanerAvailabilityScreen()),
      ),
    );
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Delete availability?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(controller.deleteCalls, equals(1));
  });

  testWidgets('availability form has service and date/time fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...availabilityOverrides(
            onboarding: CleanerOnboardingState(
              loading: false,
              profile: testCleanerProfile(status: OnboardingStatus.approved),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerAvailabilityFormScreen()),
      ),
    );
    expect(find.text('Add Availability'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('Start time'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);
    expect(find.text('End time'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('form shows a safe overlap error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...availabilityOverrides(
            onboarding: CleanerOnboardingState(
              loading: false,
              profile: testCleanerProfile(status: OnboardingStatus.approved),
            ),
            availability: AvailabilityState(
              loading: false,
              errorMessage: messageForApiCode('availability_overlap'),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerAvailabilityFormScreen()),
      ),
    );
    expect(
      find.text('This availability window overlaps another slot.'),
      findsOneWidget,
    );
  });
}
