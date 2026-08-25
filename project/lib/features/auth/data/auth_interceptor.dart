import 'package:dio/dio.dart';
import 'package:home_cleaning_marketplace/core/network/auth_session_events.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_token_storage.dart';
import 'package:home_cleaning_marketplace/features/auth/data/single_flight_refresher.dart';

/// Attaches Bearer access tokens and performs single-flight refresh on 401.
///
/// Never logs headers, tokens, or request bodies.
class AuthInterceptor extends Interceptor {
  /// Creates an interceptor. [refreshTokens] must use a Dio client without
  /// this interceptor.
  AuthInterceptor({
    required this.storage,
    required this.refreshTokens,
    required this.events,
    required this.dio,
    SingleFlightRefresher? refresher,
  }) : refresher = refresher ?? SingleFlightRefresher();

  /// Request extra key marking a request that has already been retried.
  static const String retryExtraKey = 'auth_retry';

  final AuthTokenStorage storage;
  final Future<AuthTokenPair> Function(String refreshToken) refreshTokens;
  final AuthSessionEventBus events;
  final Dio dio;
  final SingleFlightRefresher refresher;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (_isRefreshRequest(options)) {
        handler.next(options);
        return;
      }
      final pair = await storage.read();
      if (pair != null && pair.accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer ${pair.accessToken}';
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      if (err.response?.statusCode != 401) {
        handler.next(err);
        return;
      }
      if (err.requestOptions.extra[retryExtraKey] == true) {
        handler.next(err);
        return;
      }
      if (_isRefreshRequest(err.requestOptions)) {
        handler.next(err);
        return;
      }

      final pair = await _refreshPair();
      final request = err.requestOptions;
      request.extra[retryExtraKey] = true;
      request.headers['Authorization'] = 'Bearer ${pair.accessToken}';
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<AuthTokenPair> _refreshPair() {
    return refresher.run(() async {
      try {
        final current = await storage.read();
        if (current == null || current.refreshToken.isEmpty) {
          throw const AuthFailure(
            code: 'invalid_refresh_token',
            message: 'Your session has expired. Please sign in again.',
          );
        }
        final next = await refreshTokens(current.refreshToken);
        await storage.write(next);
        return next;
      } catch (_) {
        await storage.clear();
        events.emitExpired();
        rethrow;
      }
    });
  }

  static bool _isRefreshRequest(RequestOptions options) {
    final path = options.uri.path;
    return path.endsWith('/api/v1/auth/refresh') ||
        path.endsWith('/auth/refresh');
  }
}
