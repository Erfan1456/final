import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

/// Authentication lifecycle used by routing and screens.
enum AuthStatus {
  /// Secure storage is being read and /account/me may be in flight.
  restoring,

  /// No usable session.
  unauthenticated,

  /// Current user is known.
  authenticated,
}

/// Immutable authentication UI state.
class AuthState {
  /// Creates an explicit state.
  const AuthState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.errorCode,
  });

  /// Startup restoration.
  const AuthState.restoring()
    : status = AuthStatus.restoring,
      user = null,
      isSubmitting = false,
      errorMessage = null,
      errorCode = null;

  /// Logged out or unrestorable.
  const AuthState.unauthenticated({
    this.errorMessage,
    this.errorCode,
    this.isSubmitting = false,
  }) : status = AuthStatus.unauthenticated,
       user = null;

  /// Signed in as [user].
  const AuthState.authenticated(
    AuthUser this.user, {
    this.isSubmitting = false,
    this.errorMessage,
  }) : status = AuthStatus.authenticated,
       errorCode = null;

  final AuthStatus status;
  final AuthUser? user;
  final bool isSubmitting;
  final String? errorMessage;
  final String? errorCode;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isSubmitting,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}
