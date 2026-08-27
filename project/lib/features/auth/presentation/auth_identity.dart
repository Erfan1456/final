import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

/// Watches the authenticated user id so user-scoped controllers rebuild when
/// the signed-in identity changes (including logout → null).
///
/// Returns `null` while unauthenticated. During [AuthStatus.restoring], returns
/// the current user id (usually null) without treating restore as a logout.
String? watchAuthIdentityKey(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth.status == AuthStatus.unauthenticated) {
    return null;
  }
  if (auth.status == AuthStatus.authenticated) {
    return auth.user?.id;
  }
  // Restoring: expose a stable non-null sentinel so auto-load controllers can
  // still run before session restore completes (unit tests / cold start).
  return auth.user?.id ?? '__restoring__';
}

/// Whether user-scoped controllers should keep or load session-bound data.
bool watchHasAuthSession(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.status != AuthStatus.unauthenticated;
}
