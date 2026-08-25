import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_home_screen.dart';

import '../../helpers/auth_test_fakes.dart';
import '../../helpers/feature_test_fakes.dart';

Future<void> pumpApp(
  WidgetTester tester,
  AuthState state, {
  bool settle = true,
  SeededAuthController? controller,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => controller ?? SeededAuthController(state),
        ),
        ...featureControllerOverrides(),
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

  testWidgets('customer session reaches customer home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    expect(find.text('Home Cleaning Service Marketplace'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('authenticated customer cannot remain on login', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('cleaner session reaches cleaner home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    expect(find.text('Cleaner home'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
  });

  testWidgets('admin session reaches admin home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Cleaner Approvals'), findsOneWidget);
  });

  testWidgets('/home redirects a customer to customer home', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    GoRouter.of(context).go(AppRoutes.homePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('customer cannot remain on cleaner or admin routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    final context = tester.element(find.byType(CustomerHomeScreen));
    final router = GoRouter.of(context);
    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Manage Profile'), findsOneWidget);
  });

  testWidgets('cleaner cannot remain on customer or admin routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'cleaner')));
    final context = tester.element(find.text('Cleaner home'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
    router.go(AppRoutes.adminHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Cleaner home'), findsOneWidget);
  });

  testWidgets('admin cannot remain on customer or cleaner routes', (
    tester,
  ) async {
    await pumpApp(tester, AuthState.authenticated(testUser(role: 'admin')));
    final context = tester.element(find.text('Admin Dashboard'));
    final router = GoRouter.of(context);
    router.go(AppRoutes.customerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
    router.go(AppRoutes.cleanerHomePath);
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('logout redirects to login', (tester) async {
    await pumpApp(tester, AuthState.authenticated(testUser()));
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('session expiry redirects to login', (tester) async {
    final controller = SeededAuthController(
      AuthState.authenticated(testUser()),
    );
    await pumpApp(
      tester,
      AuthState.authenticated(testUser()),
      controller: controller,
    );
    controller.expireSession();
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
