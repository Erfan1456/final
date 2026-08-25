import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_user_api.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_management_controller.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  Future<ResponseBody> Function(RequestOptions options) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  test('admin user list and detail omit password fields', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      if (options.path.endsWith('/users')) {
        return ResponseBody.fromString(
          jsonEncode(
            successEnvelope(<String, dynamic>{
              'items': [adminUserJson()],
              'next_cursor': 'next',
            }),
          ),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode(
          successEnvelope(<String, dynamic>{
            'user': adminUserJson(),
            'profile': customerProfileJson(),
            'protected_admin_account': false,
            'booking_count': 1,
            'payment_count': 0,
            'active_dispute_count': 0,
          }),
        ),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final api = AdminUserApi(dio);
    final page = await api.list(role: 'customer', status: 'active');
    expect(page.items.single.email, 'pat.customer@example.com');
    expect(jsonEncode(adminUserJson()).contains('password'), isFalse);
    final detail = await api.get('id');
    expect(detail.protectedAdminAccount, isFalse);
    expect(detail.bookingCount, 1);
  });

  test('controller list filter pagination and safe error', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.invalid'));
    dio.httpClientAdapter = _Adapter((options) async {
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'success': false,
          'error': <String, String>{
            'code': 'protected_admin_account',
            'message':
                'Administrator accounts cannot be changed from this screen.',
          },
        }),
        403,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final container = ProviderContainer(
      overrides: [adminUserApiProvider.overrideWithValue(AdminUserApi(dio))],
    );
    addTearDown(container.dispose);
    await container.read(adminUserManagementControllerProvider.notifier).load();
    expect(
      container.read(adminUserManagementControllerProvider).errorMessage,
      contains('Administrator accounts'),
    );
    expect(messageForApiCode('user_not_found'), 'User was not found.');
    expect(
      messageForApiCode('invalid_account_state'),
      contains('current state'),
    );
  });
}
