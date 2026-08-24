import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/config/app_config.dart';

/// Shared HTTP transport.
///
/// Future feature services should depend on this provider instead of
/// constructing arbitrary [Dio] instances. This layer does not perform
/// requests, log bodies, attach bearer tokens, or implement authentication.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );
});
