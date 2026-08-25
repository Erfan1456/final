import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/signup_screen.dart';

import '../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('signup fields render with Customer and Cleaner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const AuthState.unauthenticated()),
          ),
        ],
        child: const MaterialApp(home: SignupScreen()),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Cleaner'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('15–128 characters'), findsOneWidget);
  });

  testWidgets('signup enforces the password length rule', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const AuthState.unauthenticated()),
          ),
        ],
        child: const MaterialApp(home: SignupScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(
      find.text('Password must be at least 15 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('successful signup submits the selected role', (tester) async {
    final controller = SeededAuthController(const AuthState.unauthenticated());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: SignupScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'fifteenCharsPass',
    );
    await tester.tap(find.text('Cleaner'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(controller.signupCalls, equals(1));
  });
}
