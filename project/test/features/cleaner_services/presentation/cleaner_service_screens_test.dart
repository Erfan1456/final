import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/catalog/presentation/catalog_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_management_screen.dart';

import '../../../helpers/feature_test_fakes.dart';

Future<void> pumpServices(
  WidgetTester tester, {
  required CleanerOnboardingState onboarding,
  CatalogState? catalog,
  CleanerServiceState? offerings,
  SeededCleanerServiceController? controller,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cleanerOnboardingControllerProvider.overrideWith(
          () => SeededCleanerOnboardingController(onboarding),
        ),
        catalogControllerProvider.overrideWith(
          () => SeededCatalogController(
            catalog ??
                CatalogState(loading: false, items: [testMarketplaceService()]),
          ),
        ),
        cleanerServiceControllerProvider.overrideWith(
          () =>
              controller ??
              SeededCleanerServiceController(
                offerings ?? const CleanerServiceState(loading: false),
              ),
        ),
      ],
      child: const MaterialApp(home: CleanerServiceManagementScreen()),
    ),
  );
}

void main() {
  testWidgets('unapproved cleaner sees approval required', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(),
      ),
    );
    expect(find.text('Approval required'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('approved cleaner sees the Home Cleaning form', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
    );
    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.text('Billing: hourly'), findsOneWidget);
    expect(
      find.text('Enter the hourly price in the smallest currency unit.'),
      findsOneWidget,
    );
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('rate must be a whole number', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '12.5');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Hourly rate must be a whole number.'), findsOneWidget);
  });

  testWidgets('currency must be three letters', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '250000');
    await tester.enterText(find.byType(TextField).at(1), 'BD');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Currency code must be three letters.'), findsOneWidget);
  });

  testWidgets('save loading disables the save button', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
      offerings: const CleanerServiceState(loading: false, saving: true),
    );
    expect(find.text('Saving...'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('inactive offering shows reactivate', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
      offerings: CleanerServiceState(
        loading: false,
        offerings: [testCleanerServiceOffering(isActive: false)],
      ),
    );
    expect(find.text('Reactivate'), findsOneWidget);
    expect(find.text('Deactivate'), findsNothing);
  });

  testWidgets('active offering can deactivate', (tester) async {
    final controller = SeededCleanerServiceController(
      CleanerServiceState(
        loading: false,
        offerings: [testCleanerServiceOffering()],
      ),
    );
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
      controller: controller,
    );
    await tester.tap(find.text('Deactivate'));
    await tester.pump();
    expect(controller.deactivateCalls, equals(1));
  });

  testWidgets('approval failure message is shown', (tester) async {
    await pumpServices(
      tester,
      onboarding: CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
      offerings: CleanerServiceState(
        loading: false,
        errorMessage: messageForApiCode('cleaner_not_approved'),
      ),
    );
    expect(
      find.text(
        'Your cleaner account must be approved before managing services.',
      ),
      findsOneWidget,
    );
  });
}
