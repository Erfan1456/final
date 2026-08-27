import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/data/signup_result.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/signup_screen.dart';

import '../../../helpers/auth_test_fakes.dart';

class _FakeSignupApi extends AuthApi {
  _FakeSignupApi() : super(plain: Dio(), authenticated: Dio());

  int signupCalls = 0;
  String? lastRole;

  @override
  Future<SignupResult> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    signupCalls += 1;
    lastRole = role;
    return testSignupResult(role: role, email: email);
  }
}

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

  testWidgets('successful signup navigates to verification pending', (
    tester,
  ) async {
    final api = _FakeSignupApi();
    final repository = AuthRepository(
      api: api,
      storage: InMemoryAuthTokenStorage(),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SignupScreen()),
        GoRoute(
          path: AppRoutes.verifyEmailPendingPath,
          builder: (context, state) {
            return Scaffold(
              body: Text(state.uri.queryParameters['email'] ?? ''),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
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
    await tester.pumpAndSettle();
    expect(api.signupCalls, equals(1));
    expect(api.lastRole, equals('cleaner'));
    expect(find.text('person@example.com'), findsOneWidget);
  });
}
