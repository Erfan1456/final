import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_session_state.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

/// Riverpod authentication controller.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<AuthSessionEvent>? _sessionSubscription;

  @override
  AuthState build() {
    final events = ref.read(authSessionEventsProvider);
    _sessionSubscription = events.stream.listen((event) {
      if (event == AuthSessionEvent.expired) {
        state = const AuthState.unauthenticated();
      }
    });
    ref.onDispose(() {
      _sessionSubscription?.cancel();
    });
    Future<void>(restoreSession);
    return const AuthState.restoring();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Restores a previous session once at startup.
  Future<void> restoreSession() async {
    try {
      final user = await _repository.restoreSession();
      if (!ref.mounted) {
        return;
      }
      if (state.status != AuthStatus.restoring) {
        return;
      }
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (state.status != AuthStatus.restoring) {
        return;
      }
      state = AuthState.unauthenticated(errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      if (state.status != AuthStatus.restoring) {
        return;
      }
      state = const AuthState.unauthenticated();
    }
  }

  /// Signs in with email and password.
  Future<void> login({required String email, required String password}) {
    return _submit(() => _repository.login(email: email, password: password));
  }

  /// Creates an account and signs in.
  Future<void> signup({
    required String email,
    required String password,
    required String role,
  }) {
    return _submit(
      () => _repository.signUp(email: email, password: password, role: role),
    );
  }

  /// Logs out this device.
  Future<void> logout() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.logout();
    } finally {
      if (ref.mounted) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  /// Logs out every device, then this one.
  Future<void> logoutAll() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.logoutAll();
    } finally {
      if (ref.mounted) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<void> _submit(Future<AuthUser> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await action();
      if (!ref.mounted) {
        return;
      }
      state = AuthState.authenticated(user);
    } on AuthFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = AuthState.unauthenticated(
        errorMessage: error.message,
        isSubmitting: false,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const AuthState.unauthenticated(
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }
}

/// Application authentication state.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
