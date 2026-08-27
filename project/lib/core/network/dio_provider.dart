import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/config/app_config.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_api.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_interceptor.dart';
import 'package:home_cleaning_marketplace/features/auth/data/flutter_secure_auth_token_storage.dart';

BaseOptions _baseOptions(AppConfig config) {
  return BaseOptions(
    baseUrl: config.normalizedApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: const <String, String>{'Accept': 'application/json'},
  );
}

/// Public HTTP transport without Bearer attachment or refresh.
final plainDioProvider = Provider<Dio>((ref) {
  return Dio(_baseOptions(ref.watch(appConfigProvider)));
});

/// Shared HTTP transport used by non-authenticated callers.
///
/// Protected feature services should use [authenticatedDioProvider].
final dioProvider = Provider<Dio>((ref) => ref.watch(plainDioProvider));

/// HTTP transport that attaches access tokens and refreshes on 401.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions(ref.watch(appConfigProvider)));
  final plain = ref.watch(plainDioProvider);
  dio.interceptors.add(
    AuthInterceptor(
      storage: ref.watch(authTokenStorageProvider),
      events: ref.watch(authSessionEventsProvider),
      dio: dio,
      refreshTokens: (refreshToken) => AuthApi.refreshWith(plain, refreshToken),
    ),
  );
  return dio;
});

/// Authentication HTTP API.
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    plain: ref.watch(plainDioProvider),
    authenticated: ref.watch(authenticatedDioProvider),
  );
});
