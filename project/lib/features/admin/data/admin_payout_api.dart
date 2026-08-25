import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_finance_models.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

class AdminPayoutApi {
  AdminPayoutApi(this._dio);

  final Dio _dio;

  Future<CleanerPayoutPage> listPayouts({
    String? status,
    String? currency,
    String? cleanerUserId,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/payouts',
        queryParameters: <String, Object>{
          'status': ?status,
          'currency': ?currency,
          'cleaner_user_id': ?cleanerUserId,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return CleanerPayoutPage.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminPayoutDetail> getPayout(String payoutId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/payouts/$payoutId',
      );
      return AdminPayoutDetail.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayout> process(String payoutId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/payouts/$payoutId/process',
      );
      return CleanerPayout.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayout> reject({
    required String payoutId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/admin/payouts/$payoutId/reject',
        data: <String, String>{'reason': reason},
      );
      return CleanerPayout.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayout> simulateSuccess(String payoutId) {
    return _simulate(payoutId, 'success');
  }

  Future<CleanerPayout> simulateFailure(String payoutId) {
    return _simulate(payoutId, 'failure');
  }

  Future<CleanerPayout> _simulate(String payoutId, String result) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/dev/payouts/$payoutId/simulate',
        data: <String, String>{'result': result},
      );
      return CleanerPayout.fromJson(
        _requirePayout(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Map<String, dynamic> _requirePayout(Map<String, dynamic> data) {
    final payout = data['payout'];
    if (payout is Map) {
      return Map<String, dynamic>.from(payout);
    }
    return data;
  }
}

class AdminFinanceApi {
  AdminFinanceApi(this._dio);

  final Dio _dio;

  Future<AdminFinanceSummary> getSummary({
    String? from,
    String? to,
    String? currency,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/finance/summary',
        queryParameters: <String, Object>{
          'from': ?from,
          'to': ?to,
          'currency': ?currency,
        },
      );
      return AdminFinanceSummary.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<FinanceReconciliationPage> getReconciliation({
    String? currency,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/finance/reconciliation',
        queryParameters: <String, Object>{
          'currency': ?currency,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return FinanceReconciliationPage.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<AdminCleanerFinanceDetail> getCleanerFinance(String userId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/cleaners/$userId/finance',
      );
      return AdminCleanerFinanceDetail.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }
}

final adminPayoutApiProvider = Provider<AdminPayoutApi>((ref) {
  return AdminPayoutApi(ref.watch(authenticatedDioProvider));
});

final adminFinanceApiProvider = Provider<AdminFinanceApi>((ref) {
  return AdminFinanceApi(ref.watch(authenticatedDioProvider));
});
