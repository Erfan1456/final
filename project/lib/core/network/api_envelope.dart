import 'package:dio/dio.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';

/// Shared JSON envelope helpers for authenticated feature APIs.
abstract final class ApiEnvelope {
  /// Returns the `data` object from a success envelope.
  static Map<String, dynamic> requireData(dynamic body) {
    if (body is! Map) {
      throw const ApiFailure(
        code: 'invalid_response',
        message: 'The server returned an unexpected response.',
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw const ApiFailure(
        code: 'invalid_response',
        message: 'The server returned an unexpected response.',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// Maps a Dio failure without leaking internals.
  static ApiFailure mapDioException(DioException error) {
    if (error.error is ApiFailure) {
      return error.error! as ApiFailure;
    }
    if (error.error is AuthFailure) {
      final auth = error.error! as AuthFailure;
      return ApiFailure(code: auth.code, message: auth.message);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(
          code: 'network',
          message: 'Unable to reach the server. Check your connection.',
        );
      case DioExceptionType.cancel:
        return const ApiFailure(
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
          return ApiFailure(code: code, message: messageForApiCode(code));
        }
      }
    }
    return const ApiFailure(
      code: 'unknown',
      message: 'Something went wrong. Please try again.',
    );
  }
}
