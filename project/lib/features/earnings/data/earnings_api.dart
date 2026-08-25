import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_envelope.dart';
import 'package:home_cleaning_marketplace/core/network/dio_provider.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

class CleanerEarningsApi {
  CleanerEarningsApi(this._dio);

  final Dio _dio;

  Future<EarningsSummary> getSummary() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/earnings/summary',
      );
      return EarningsSummary.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<EarningsLedgerPage> getLedger({
    String? currency,
    String? entryType,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/earnings/ledger',
        queryParameters: <String, Object>{
          'currency': ?currency,
          'entry_type': ?entryType,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return EarningsLedgerPage.fromJson(
        ApiEnvelope.requireData(response.data),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayoutPage> listPayouts({
    String? status,
    String? currency,
    int? limit,
    String? after,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/payouts',
        queryParameters: <String, Object>{
          'status': ?status,
          'currency': ?currency,
          'limit': ?limit,
          'after': ?after,
        },
      );
      return CleanerPayoutPage.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayout> getPayout(String payoutId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/cleaner/payouts/$payoutId',
      );
      return CleanerPayout.fromJson(ApiEnvelope.requireData(response.data));
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayout> requestPayout({
    required int amountMinor,
    required String currencyCode,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/cleaner/payouts',
        options: Options(
          headers: <String, String>{'Idempotency-Key': idempotencyKey},
        ),
        data: <String, Object>{
          'amount_minor': amountMinor,
          'currency_code': currencyCode,
        },
      );
      return CleanerPayout.fromJson(
        _requirePayout(ApiEnvelope.requireData(response.data)),
      );
    } on DioException catch (error) {
      throw ApiEnvelope.mapDioException(error);
    }
  }

  Future<CleanerPayout> cancelPayout(String payoutId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/cleaner/payouts/$payoutId/cancel',
      );
      return CleanerPayout.fromJson(ApiEnvelope.requireData(response.data));
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

final cleanerEarningsApiProvider = Provider<CleanerEarningsApi>((ref) {
  return CleanerEarningsApi(ref.watch(authenticatedDioProvider));
});
