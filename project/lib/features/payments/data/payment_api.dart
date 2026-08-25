import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

class CustomerPaymentApi {
  CustomerPaymentApi(this._dio);

  final Dio _dio;

  Future<PaymentHistory> getPayment(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/customer/bookings/$bookingId/payment',
      );
      return PaymentHistory.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<PaymentAttempt> startPayment({
    required String bookingId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/customer/bookings/$bookingId/payment',
        options: Options(
          headers: <String, String>{'Idempotency-Key': idempotencyKey},
        ),
      );
      return PaymentAttempt.fromJson(
        _requirePayment(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<PaymentAttempt> cancelPayment(String bookingId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/customer/bookings/$bookingId/payment/cancel',
      );
      return PaymentAttempt.fromJson(
        _requirePayment(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

class SandboxPaymentApi {
  SandboxPaymentApi(this._dio);

  final Dio _dio;

  Future<PaymentAttempt> simulateSuccess(String paymentId) {
    return _simulate(paymentId, 'success');
  }

  Future<PaymentAttempt> simulateFailure(String paymentId) {
    return _simulate(paymentId, 'failure');
  }

  Future<PaymentAttempt> _simulate(String paymentId, String result) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/dev/payments/$paymentId/simulate',
        data: <String, String>{'result': result},
      );
      return PaymentAttempt.fromJson(
        _requirePayment(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

class AdminPaymentApi {
  AdminPaymentApi(this._dio);

  final Dio _dio;

  Future<AdminPaymentPage> list({
    String? status,
    String? provider,
    String? currency,
    String? bookingId,
    String? customerUserId,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/payments',
        queryParameters: <String, Object>{
          'status': ?status,
          'provider': ?provider,
          'currency': ?currency,
          'booking_id': ?bookingId,
          'customer_user_id': ?customerUserId,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return AdminPaymentPage.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminPaymentDetail> get(String paymentId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/payments/$paymentId',
      );
      return AdminPaymentDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<List<PaymentWebhookEventSummary>> events(String paymentId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/payments/$paymentId/events',
      );
      final data = ApiEnvelope.requireData(response.data);
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('Webhook event list JSON is invalid.');
      }
      return [
        for (final item in items)
          if (item is Map)
            PaymentWebhookEventSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
      ];
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminPaymentDetail> refund({
    required String paymentId,
    required String idempotencyKey,
    required String reason,
    int? amountMinor,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/payments/$paymentId/refund',
        data: <String, Object?>{'amount_minor': amountMinor, 'reason': reason},
        options: Options(
          headers: <String, String>{'Idempotency-Key': idempotencyKey},
        ),
      );
      return AdminPaymentDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

Map<String, dynamic> _requirePayment(Map<String, dynamic> data) {
  final payment = data['payment'];
  if (payment is! Map) {
    throw const FormatException('Payment JSON is invalid.');
  }
  return Map<String, dynamic>.from(payment);
}

final customerPaymentApiProvider = Provider<CustomerPaymentApi>((ref) {
  return CustomerPaymentApi(ref.watch(authenticatedDioProvider));
});

final sandboxPaymentApiProvider = Provider<SandboxPaymentApi>((ref) {
  return SandboxPaymentApi(ref.watch(authenticatedDioProvider));
});

final adminPaymentApiProvider = Provider<AdminPaymentApi>((ref) {
  return AdminPaymentApi(ref.watch(authenticatedDioProvider));
});
