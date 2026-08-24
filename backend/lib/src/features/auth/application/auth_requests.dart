import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/email_input.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';

/// Parsed signup JSON. Unknown fields are ignored.
class SignupRequest {
  /// Creates a parsed signup request.
  const SignupRequest({
    required this.email,
    required this.password,
    required this.role,
  });

  /// Reads required fields from [json].
  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(
      email: EmailInput.parse(_requireString(json, 'email')),
      password: _requireString(json, 'password'),
      role: parsePublicSignupRole(_requireString(json, 'role')),
    );
  }

  /// Trimmed display email. Not lowercased here.
  final String email;

  /// Opaque password as supplied. Never trimmed or case-folded.
  final String password;

  /// Public signup role. Never [UserRole.admin].
  final UserRole role;
}

/// Parsed login JSON. Unknown fields are ignored.
class LoginRequest {
  /// Creates a parsed login request.
  const LoginRequest({
    required this.email,
    required this.password,
  });

  /// Reads required fields from [json].
  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    final password = _requireString(json, 'password');
    if (password.isEmpty) {
      throw const InvalidAuthInputException(
        code: 'invalid_password',
        message: 'Password is required.',
      );
    }
    return LoginRequest(
      email: EmailInput.parse(_requireString(json, 'email')),
      password: password,
    );
  }

  /// Trimmed display email. Not lowercased here.
  final String email;

  /// Opaque password as supplied. Never trimmed or case-folded.
  final String password;
}

/// Parsed refresh JSON. Unknown fields are ignored.
class RefreshRequest {
  /// Creates a parsed refresh request.
  const RefreshRequest({required this.refreshToken});

  /// Reads required fields from [json].
  factory RefreshRequest.fromJson(Map<String, dynamic> json) {
    return RefreshRequest(
      refreshToken: _requireNonEmptyString(json, 'refresh_token'),
    );
  }

  /// Raw refresh token as supplied.
  final String refreshToken;
}

/// Parsed logout JSON. Unknown fields are ignored.
class LogoutRequest {
  /// Creates a parsed logout request.
  const LogoutRequest({required this.refreshToken});

  /// Reads required fields from [json].
  factory LogoutRequest.fromJson(Map<String, dynamic> json) {
    return LogoutRequest(
      refreshToken: _requireNonEmptyString(json, 'refresh_token'),
    );
  }

  /// Raw refresh token as supplied.
  final String refreshToken;
}

/// Parses a public-signup role. Admin and unknown values fail validation.
UserRole parsePublicSignupRole(String value) {
  switch (value) {
    case 'customer':
      return UserRole.customer;
    case 'cleaner':
      return UserRole.cleaner;
    default:
      throw const InvalidAuthInputException(
        code: 'invalid_role',
        message: 'Public signup allows only customer or cleaner roles.',
      );
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) {
    throw InvalidAuthInputException(
      code: 'invalid_input',
      message: '$key is required.',
    );
  }
  final value = json[key];
  if (value is! String) {
    throw InvalidAuthInputException(
      code: 'invalid_input',
      message: '$key must be a string.',
    );
  }
  return value;
}

String _requireNonEmptyString(Map<String, dynamic> json, String key) {
  final value = _requireString(json, key);
  if (value.isEmpty) {
    throw InvalidAuthInputException(
      code: 'invalid_input',
      message: '$key is required.',
    );
  }
  return value;
}
