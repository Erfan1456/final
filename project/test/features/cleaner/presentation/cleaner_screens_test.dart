import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_home_screen.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_screen.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

Future<void> pumpCleanerHome(
  WidgetTester tester,
  CleanerOnboardingState onboarding,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => SeededAuthController(
            AuthState.authenticated(testUser(role: 'cleaner')),
          ),
        ),
        cleanerOnboardingControllerProvider.overrideWith(
          () => SeededCleanerOnboardingController(onboarding),
        ),
      ],
      child: const MaterialApp(home: CleanerHomeScreen()),
    ),
  );
}

void main() {
  testWidgets('no-profile CTA is Start onboarding', (tester) async {
    await pumpCleanerHome(tester, const CleanerOnboardingState(loading: false));
    expect(find.text('Start onboarding'), findsOneWidget);
    expect(find.textContaining('Start onboarding to apply'), findsOneWidget);
  });

  testWidgets('draft shows continue onboarding', (tester) async {
    await pumpCleanerHome(
      tester,
      CleanerOnboardingState(loading: false, profile: testCleanerProfile()),
    );
    expect(find.text('Continue onboarding'), findsOneWidget);
  });

  testWidgets('pending is read-only status', (tester) async {
    await pumpCleanerHome(
      tester,
      CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.pending),
      ),
    );
    expect(
      find.text('Your application is pending administrator review.'),
      findsOneWidget,
    );
    expect(find.text('Continue onboarding'), findsNothing);
  });

  testWidgets('rejected shows reason and resubmit CTA', (tester) async {
    await pumpCleanerHome(
      tester,
      CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(
          status: OnboardingStatus.rejected,
          rejectionReason: 'Please expand the bio.',
        ),
      ),
    );
    expect(find.textContaining('Please expand the bio.'), findsOneWidget);
    expect(find.text('Edit and resubmit'), findsOneWidget);
  });

  testWidgets('approved shows service and availability actions', (
    tester,
  ) async {
    await pumpCleanerHome(
      tester,
      CleanerOnboardingState(
        loading: false,
        profile: testCleanerProfile(status: OnboardingStatus.approved),
      ),
    );
    expect(find.text('Manage Services'), findsOneWidget);
    expect(find.text('Manage Availability'), findsOneWidget);
    expect(find.text('Start onboarding'), findsNothing);
  });

  testWidgets('onboarding draft is editable', (tester) async {
    final controller = SeededCleanerOnboardingController(
      CleanerOnboardingState(loading: false, profile: testCleanerProfile()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerOnboardingControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: CleanerOnboardingScreen()),
      ),
    );
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Submit for Review'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(controller.saveCalls, equals(1));
  });

  testWidgets('pending onboarding hides edit actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerOnboardingControllerProvider.overrideWith(
            () => SeededCleanerOnboardingController(
              CleanerOnboardingState(
                loading: false,
                profile: testCleanerProfile(status: OnboardingStatus.pending),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerOnboardingScreen()),
      ),
    );
    expect(find.text('Save'), findsNothing);
    expect(find.text('Submit for Review'), findsNothing);
  });

  testWidgets('rejected onboarding shows the reason', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanerOnboardingControllerProvider.overrideWith(
            () => SeededCleanerOnboardingController(
              CleanerOnboardingState(
                loading: false,
                profile: testCleanerProfile(
                  status: OnboardingStatus.rejected,
                  rejectionReason: 'Please expand the bio.',
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerOnboardingScreen()),
      ),
    );
    expect(find.text('Rejected: Please expand the bio.'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
