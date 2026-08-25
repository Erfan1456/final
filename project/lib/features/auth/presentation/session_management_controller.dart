import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/data/account_session.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

/// Session management presentation state.
class SessionManagementState {
  const SessionManagementState({
    required this.loading,
    this.sessions = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.infoMessage,
  });

  const SessionManagementState.loading()
    : loading = true,
      sessions = const [],
      isSubmitting = false,
      errorMessage = null,
      infoMessage = null;

  final bool loading;
  final List<AccountSession> sessions;
  final bool isSubmitting;
  final String? errorMessage;
  final String? infoMessage;

  SessionManagementState copyWith({
    bool? loading,
    List<AccountSession>? sessions,
    bool? isSubmitting,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return SessionManagementState(
      loading: loading ?? this.loading,
      sessions: sessions ?? this.sessions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

/// Lists and revokes signed-in account sessions.
class SessionManagementController extends Notifier<SessionManagementState> {
  @override
  SessionManagementState build() {
    Future<void>(load);
    return const SessionManagementState.loading();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Reloads active sessions.
  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true, clearInfo: true);
    try {
      final sessions = await _repository.listSessions();
      if (!ref.mounted) {
        return;
      }
      state = SessionManagementState(loading: false, sessions: sessions);
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = SessionManagementState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const SessionManagementState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Revokes one session. Signs out locally when the current session is revoked.
  Future<void> revokeSession(String sessionId) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearInfo: true);
    try {
      final currentSessionRevoked = await _repository.revokeSession(sessionId);
      if (!ref.mounted) {
        return;
      }
      if (currentSessionRevoked) {
        await _repository.logout();
        ref.read(authControllerProvider.notifier).clearAuthenticatedSession();
        return;
      }
      await load();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        infoMessage: 'Session revoked.',
      );
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Revokes every session and signs out locally.
  Future<void> revokeAllSessions() async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearInfo: true);
    try {
      await _repository.logoutAll();
      if (!ref.mounted) {
        return;
      }
      ref.read(authControllerProvider.notifier).clearAuthenticatedSession();
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }
}

final sessionManagementControllerProvider =
    NotifierProvider<SessionManagementController, SessionManagementState>(
      SessionManagementController.new,
    );
