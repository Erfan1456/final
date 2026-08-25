import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/authenticated_home_screen.dart';

import '../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('home shows safe email and role', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(
              AuthState.authenticated(testUser(email: 'person@example.com')),
            ),
          ),
        ],
        child: const MaterialApp(home: AuthenticatedHomeScreen()),
      ),
    );

    expect(find.text('Email: person@example.com'), findsOneWidget);
    expect(find.text('Role: customer'), findsOneWidget);
    expect(find.text('Email not verified'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Log out all devices'), findsOneWidget);
  });

  testWidgets('home logout actions fire controller methods', (tester) async {
    final controller = SeededAuthController(
      AuthState.authenticated(testUser()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AuthenticatedHomeScreen()),
      ),
    );

    await tester.tap(find.text('Log out'));
    await tester.pump();
    expect(controller.logoutCalls, equals(1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AuthenticatedHomeScreen()),
      ),
    );
    await tester.tap(find.text('Log out all devices'));
    await tester.pump();
    expect(controller.logoutAllCalls, equals(1));
  });
}
