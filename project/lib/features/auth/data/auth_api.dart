import 'package:dio/dio.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';

/// HTTP client for public and protected authentication endpoints.
class AuthApi {
  /// Creates an API over [plain] (no Bearer refresh) and [authenticated].
  AuthApi({required this.plain, required this.authenticated});

  /// Dio client without Bearer refresh handling.
  final Dio plain;

  /// Dio client with Bearer attachment and single-flight refresh.
  final Dio authenticated;

  /// Public signup. Returns the user and issued token pair.
  Future<({AuthUser user, AuthTokenPair tokens})> signUp({
    required String email,
    required String password,
    required String role,
  }) {
    _ensureBaseUrl(plain);
    return _sendAuthForm(
      plain.post<dynamic>(
        '/api/v1/auth/signup',
        data: <String, String>{
          'email': email,
          'password': password,
          'role': role,
        },
      ),
    );
  }

  /// Public login. Returns the user and issued token pair.
  Future<({AuthUser user, AuthTokenPair tokens})> login({
    required String email,
    required String password,
  }) {
    _ensureBaseUrl(plain);
    return _sendAuthForm(
      plain.post<dynamic>(
        '/api/v1/auth/login',
        data: <String, String>{'email': email, 'password': password},
      ),
    );
  }

  /// Rotates tokens using the public refresh endpoint.
  Future<AuthTokenPair> refresh(String refreshToken) {
    return refreshWith(plain, refreshToken);
  }

  /// Refresh helper used by the interceptor so it never uses authenticated Dio.
  static Future<AuthTokenPair> refreshWith(
    Dio plain,
    String refreshToken,
  ) async {
    _ensureBaseUrl(plain);
    try {
      final response = await plain.post<dynamic>(
        '/api/v1/auth/refresh',
        data: <String, String>{'refresh_token': refreshToken},
      );
      final tokens = _requireMap(_requireData(response.data)['tokens']);
      return AuthTokenPair.fromJson(tokens);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Public logout using the current refresh token.
  Future<void> logout(String refreshToken) async {
    _ensureBaseUrl(plain);
    try {
      await plain.post<dynamic>(
        '/api/v1/auth/logout',
        data: <String, String>{'refresh_token': refreshToken},
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Protected current-account lookup.
  Future<AuthUser> me() async {
    _ensureBaseUrl(authenticated);
    try {
      final response = await authenticated.get<dynamic>('/api/v1/account/me');
      final user = _requireMap(_requireData(response.data)['user']);
      return AuthUser.fromJson(user);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Protected revoke-all-sessions.
  Future<void> revokeAllSessions() async {
    _ensureBaseUrl(authenticated);
    try {
      await authenticated.delete<dynamic>('/api/v1/account/sessions');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<({AuthUser user, AuthTokenPair tokens})> _sendAuthForm(
    Future<Response<dynamic>> request,
  ) async {
    _ensureBaseUrl(plain);
    try {
      final response = await request;
      final data = _requireData(response.data);
      return (
        user: AuthUser.fromJson(_requireMap(data['user'])),
        tokens: AuthTokenPair.fromJson(_requireMap(data['tokens'])),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  static void _ensureBaseUrl(Dio dio) {
    if (dio.options.baseUrl.trim().isEmpty) {
      throw const AuthFailure(
        code: 'not_configured',
        message: 'The API is not configured. Set API_BASE_URL and try again.',
      );
    }
  }

  static Map<String, dynamic> _requireData(dynamic body) {
    if (body is! Map) {
      throw const AuthFailure(
        code: 'invalid_response',
        message: 'The server returned an unexpected response.',
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw const AuthFailure(
        code: 'invalid_response',
        message: 'The server returned an unexpected response.',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  static Map<String, dynamic> _requireMap(dynamic value) {
    if (value is! Map) {
      throw const AuthFailure(
        code: 'invalid_response',
        message: 'The server returned an unexpected response.',
      );
    }
    return Map<String, dynamic>.from(value);
  }

  /// Maps a Dio failure to [AuthFailure] without leaking internals.
  static AuthFailure mapDioException(DioException error) {
    if (error.error is AuthFailure) {
      return error.error! as AuthFailure;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return const AuthFailure(
          code: 'network',
          message: 'Unable to reach the server. Check your connection.',
        );
      case DioExceptionType.cancel:
        return const AuthFailure(
          code: 'cancelled',
          message: 'The request was cancelled.',
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map) {
        final code = nested['code'];
        if (code is String && code.isNotEmpty) {
          return AuthFailure(code: code, message: messageForCode(code));
        }
      }
    }

    final status = error.response?.statusCode;
    if (status == 401) {
      return const AuthFailure(
        code: 'invalid_access_token',
        message: 'Authentication is required.',
      );
    }
    if (status == 403) {
      return const AuthFailure(
        code: 'account_unavailable',
        message: 'This account is currently unavailable.',
      );
    }
    if (status == 503) {
      return const AuthFailure(
        code: 'authentication_unavailable',
        message: 'Authentication is temporarily unavailable.',
      );
    }
    return const AuthFailure(
      code: 'unknown',
      message: 'Something went wrong. Please try again.',
    );
  }

  /// User-readable messages for known backend error codes.
  static String messageForCode(String code) {
    switch (code) {
      case 'invalid_credentials':
        return 'Invalid email or password.';
      case 'duplicate_email':
        return 'An account with this email already exists.';
      case 'account_unavailable':
        return 'This account is currently unavailable.';
      case 'invalid_refresh_token':
        return 'Your session has expired. Please sign in again.';
      case 'invalid_access_token':
        return 'Authentication is required.';
      case 'authentication_unavailable':
        return 'Authentication is temporarily unavailable.';
      case 'invalid_email':
        return 'Enter a valid email address.';
      case 'invalid_password':
        return 'Check your password and try again.';
      case 'invalid_role':
        return 'Choose Customer or Cleaner.';
      case 'invalid_input':
        return 'Please check your details and try again.';
      case 'invalid_json':
        return 'Please check your details and try again.';
      case 'not_configured':
        return 'The API is not configured. Set API_BASE_URL and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
