import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/auth/data/account_session.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/session_management_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/session_management_screen.dart';

import '../../../helpers/auth_test_fakes.dart';

AccountSession testAccountSession({
  String id = '507f1f77bcf86cd7994390aa',
  bool isCurrent = false,
}) {
  final created = DateTime.utc(2026, 8, 25, 12);
  return AccountSession(
    id: id,
    createdAt: created,
    expiresAt: created.add(const Duration(days: 30)),
    lastRotatedAt: created,
    isCurrent: isCurrent,
  );
}

class _SeededSessionManagementController extends SessionManagementController {
  _SeededSessionManagementController(this._seed);

  final SessionManagementState _seed;
  int revokeCalls = 0;
  int revokeAllCalls = 0;
  String? lastRevokedId;

  @override
  SessionManagementState build() => _seed;

  @override
  Future<void> load() async {}

  @override
  Future<void> revokeSession(String sessionId) async {
    revokeCalls += 1;
    lastRevokedId = sessionId;
    final current = _seed.sessions.any(
      (session) => session.id == sessionId && session.isCurrent,
    );
    if (current) {
      ref.read(authControllerProvider.notifier).clearAuthenticatedSession();
    }
  }

  @override
  Future<void> revokeAllSessions() async {
    revokeAllCalls += 1;
    ref.read(authControllerProvider.notifier).clearAuthenticatedSession();
  }
}

void main() {
  Future<_SeededSessionManagementController> pumpSessions(
    WidgetTester tester, {
    required List<AccountSession> sessions,
    required SeededAuthController auth,
  }) async {
    final controller = _SeededSessionManagementController(
      SessionManagementState(loading: false, sessions: sessions),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          sessionManagementControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: SessionManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Ensure seeded auth notifier is attached before assertions on auth.state.
    ProviderScope.containerOf(
      tester.element(find.byType(SessionManagementScreen)),
    ).read(authControllerProvider);
    return controller;
  }

  testWidgets(
    'other session revoke asks for confirmation; cancel does not revoke',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = SeededAuthController(AuthState.authenticated(testUser()));
      final sessions = await pumpSessions(
        tester,
        auth: auth,
        sessions: [
          testAccountSession(id: '507f1f77bcf86cd7994390c1', isCurrent: true),
          testAccountSession(id: '507f1f77bcf86cd7994390c2'),
        ],
      );

      await tester.tap(find.byTooltip('Revoke session'));
      await tester.pumpAndSettle();
      expect(find.text('Revoke session?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sessions.revokeCalls, equals(0));
      expect(auth.state.status, equals(AuthStatus.authenticated));
    },
  );

  testWidgets(
    'confirming other session revoke calls revoke path without clearing auth',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = SeededAuthController(AuthState.authenticated(testUser()));
      final sessions = await pumpSessions(
        tester,
        auth: auth,
        sessions: [
          testAccountSession(id: '507f1f77bcf86cd7994390c1', isCurrent: true),
          testAccountSession(id: '507f1f77bcf86cd7994390c2'),
        ],
      );

      await tester.tap(find.byTooltip('Revoke session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke'));
      await tester.pumpAndSettle();
      expect(sessions.revokeCalls, equals(1));
      expect(sessions.lastRevokedId, equals('507f1f77bcf86cd7994390c2'));
      expect(auth.state.status, equals(AuthStatus.authenticated));
    },
  );

  testWidgets(
    'revoke all sessions asks for confirmation; cancel does not revoke',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = SeededAuthController(AuthState.authenticated(testUser()));
      final sessions = await pumpSessions(
        tester,
        auth: auth,
        sessions: [
          testAccountSession(id: '507f1f77bcf86cd7994390c1', isCurrent: true),
        ],
      );

      await tester.tap(find.text('Sign out all devices'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out all devices?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sessions.revokeAllCalls, equals(0));
      expect(auth.state.status, equals(AuthStatus.authenticated));
    },
  );

  testWidgets('confirming revoke all sessions clears local auth', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = SeededAuthController(AuthState.authenticated(testUser()));
    final sessions = await pumpSessions(
      tester,
      auth: auth,
      sessions: [
        testAccountSession(id: '507f1f77bcf86cd7994390c1', isCurrent: true),
      ],
    );

    await tester.tap(find.text('Sign out all devices'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out all'));
    await tester.pumpAndSettle();
    expect(sessions.revokeAllCalls, equals(1));
    expect(auth.state.status, equals(AuthStatus.unauthenticated));
  });

  testWidgets(
    'current session revoke asks for confirmation; cancel keeps session',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = SeededAuthController(AuthState.authenticated(testUser()));
      final sessions = await pumpSessions(
        tester,
        auth: auth,
        sessions: [
          testAccountSession(id: '507f1f77bcf86cd7994390c1', isCurrent: true),
          testAccountSession(id: '507f1f77bcf86cd7994390c2'),
        ],
      );

      expect(find.text('This device (current session)'), findsOneWidget);
      await tester.tap(find.byTooltip('Revoke current session'));
      await tester.pumpAndSettle();

      expect(find.text('End this session?'), findsOneWidget);
      expect(
        find.textContaining('You will need to sign in again'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sessions.revokeCalls, equals(0));
      expect(auth.state.status, equals(AuthStatus.authenticated));
    },
  );

  testWidgets('confirming current session revoke clears local auth', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = SeededAuthController(AuthState.authenticated(testUser()));
    final sessions = await pumpSessions(
      tester,
      auth: auth,
      sessions: [
        testAccountSession(id: '507f1f77bcf86cd7994390c1', isCurrent: true),
      ],
    );

    await tester.tap(find.byTooltip('Revoke current session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();

    expect(sessions.revokeCalls, equals(1));
    expect(sessions.lastRevokedId, equals('507f1f77bcf86cd7994390c1'));
    expect(auth.state.status, equals(AuthStatus.unauthenticated));
  });
}
