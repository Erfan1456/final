import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/login_screen.dart';

import '../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('login fields render and password is obscured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const AuthState.unauthenticated()),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    final passwordField = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(TextField),
      ),
    );
    expect(passwordField.obscureText, isTrue);
  });

  testWidgets('login validates empty fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const AuthState.unauthenticated()),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('login shows a safe error', (tester) async {
    final controller = SeededAuthController(const AuthState.unauthenticated())
      ..nextError = 'Invalid email or password.';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: LoginScreen()),
      ),
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
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('login shows verify email action for email_not_verified', (
    tester,
  ) async {
    final controller = SeededAuthController(const AuthState.unauthenticated())
      ..nextError = 'Verify your email before signing in.'
      ..nextErrorCode = 'email_not_verified';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: LoginScreen()),
      ),
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
    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('login shows forgot password link', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const AuthState.unauthenticated()),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('login shows loading while submitting', (tester) async {
    final controller = SeededAuthController(const AuthState.unauthenticated())
      ..submitGate = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: LoginScreen()),
      ),
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    controller.submitGate!.complete();
    await tester.pump();
  });

  testWidgets('login link navigates to signup', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => SeededAuthController(const AuthState.unauthenticated()),
          ),
        ],
        child: const HomeCleaningMarketplaceApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Cleaner'), findsOneWidget);
  });
}
