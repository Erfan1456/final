import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

import '../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('app boots the login screen when unauthenticated', (
    tester,
  ) async {
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

    expect(find.text('Home Cleaning Service Marketplace'), findsWidgets);
    expect(find.text('Sign in'), findsWidgets);
  });
}
