import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

import '../../helpers/auth_test_fakes.dart';

Future<void> pumpApp(
  WidgetTester tester,
  AuthState state, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => SeededAuthController(state)),
      ],
      child: const HomeCleaningMarketplaceApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('restoring shows splash', (tester) async {
    await pumpApp(tester, const AuthState.restoring(), settle: false);
    expect(find.text('Restoring session...'), findsOneWidget);
  });

  testWidgets('unauthenticated shows login', (tester) async {
    await pumpApp(tester, const AuthState.unauthenticated());
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('unauthenticated can open signup', (tester) async {
    await pumpApp(tester, const AuthState.unauthenticated());
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Customer'), findsOneWidget);
  });

  testWidgets('authenticated shows home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.text('Email: person@example.com'), findsOneWidget);
  });

  testWidgets('authenticated cannot remain on login', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('logout redirects to login', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('restored session reaches home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    expect(find.text('Role: cleaner'), findsOneWidget);
    expect(find.text('Signed in'), findsOneWidget);
  });
}
