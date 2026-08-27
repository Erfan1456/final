import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

import '../helpers/auth_test_fakes.dart';
import '../helpers/feature_test_fakes.dart';

/// Pumps the full app shell with seeded auth and feature controller fakes.
Future<SeededAuthController> pumpAcceptanceApp(
  WidgetTester tester,
  AuthState state, {
  SeededAuthController? controller,
  List<dynamic> Function()? featureOverrides,
  bool settle = true,
}) async {
  // Dispose any prior ProviderScope so override lists can change safely.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  final auth = controller ?? SeededAuthController(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        ...(featureOverrides?.call() ?? featureControllerOverrides()),
      ],
      child: const HomeCleaningMarketplaceApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return auth;
}

/// Resolves [GoRouter] from a visible finder.
GoRouter routerOf(WidgetTester tester, Finder finder) {
  return GoRouter.of(tester.element(finder));
}

/// Captures layout overflow errors while [body] runs.
Future<List<FlutterErrorDetails>> captureOverflowErrors(
  Future<void> Function() body,
) async {
  final overflows = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = '${details.exceptionAsString()}\n${details.stack}';
    if (text.contains('overflowed') ||
        text.contains('A RenderFlex overflowed')) {
      overflows.add(details);
    }
    previous?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return overflows;
}

/// Sets a phone-sized surface and large text scale for accessibility checks.
void applyCompactAccessibleSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
}

/// Resets view overrides applied by [applyCompactAccessibleSurface].
void resetCompactAccessibleSurface(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
}

/// Pumps a single screen under MaterialApp with optional Riverpod overrides.
Future<void> pumpAcceptanceScreen(
  WidgetTester tester,
  Widget screen, {
  List<dynamic> overrides = const [],
  bool compactAccessible = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  if (compactAccessible) {
    applyCompactAccessibleSurface(tester);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}
