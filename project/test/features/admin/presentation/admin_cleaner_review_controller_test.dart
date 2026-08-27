import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_api.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/feature_test_fakes.dart';

class _FakeAdminApi extends AdminCleanerApi {
  _FakeAdminApi() : super(Dio());

  AdminCleanerApplicationPage page = const AdminCleanerApplicationPage(
    items: <AdminCleanerApplicationSummary>[],
    nextCursor: null,
  );
  AdminCleanerApplicationDetail? detail;
  ApiFailure? nextError;
  String? lastStatus;
  String? lastAfter;
  int listCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<AdminCleanerApplicationPage> list({
    String? status,
    String? after,
    int? limit,
  }) async {
    listCalls += 1;
    lastStatus = status;
    lastAfter = after;
    _throwIfNeeded();
    return page;
  }

  @override
  Future<AdminCleanerApplicationDetail> get(String userId) async {
    _throwIfNeeded();
    return detail!;
  }

  @override
  Future<CleanerProfile> approve(String userId) async {
    approveCalls += 1;
    _throwIfNeeded();
    return CleanerProfile.fromJson(cleanerProfileJson(status: 'approved'));
  }

  @override
  Future<CleanerProfile> reject(String userId, String reason) async {
    rejectCalls += 1;
    _throwIfNeeded();
    return CleanerProfile.fromJson(
      cleanerProfileJson(status: 'rejected', rejectionReason: reason),
    );
  }
}

void main() {
  late _FakeAdminApi api;
  late ProviderContainer container;

  AdminCleanerApplicationSummary summary() {
    return AdminCleanerApplicationSummary.fromJson(adminSummaryJson());
  }

  setUp(() {
    api = _FakeAdminApi();
    container = ProviderContainer(
      overrides: [
        ...authenticatedAuthOverrides(),
        adminCleanerApiProvider.overrideWithValue(api),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<AdminCleanerReviewState> settle() async {
    container.listen(adminCleanerReviewControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(adminCleanerReviewControllerProvider);
  }

  test('pending list loads by default', () async {
    api.page = AdminCleanerApplicationPage(
      items: [summary()],
      nextCursor: 'c2',
    );
    final state = await settle();
    expect(state.statusFilter, equals('pending'));
    expect(state.items, hasLength(1));
    expect(state.nextCursor, equals('c2'));
    expect(api.lastStatus, equals('pending'));
  });

  test('filter changes status and reloads', () async {
    await settle();
    await container
        .read(adminCleanerReviewControllerProvider.notifier)
        .load(status: 'approved');
    expect(api.lastStatus, equals('approved'));
    expect(
      container.read(adminCleanerReviewControllerProvider).statusFilter,
      equals('approved'),
    );
  });

  test('load more uses next_cursor', () async {
    api.page = AdminCleanerApplicationPage(
      items: [summary()],
      nextCursor: 'c2',
    );
    await settle();
    api.page = const AdminCleanerApplicationPage(
      items: <AdminCleanerApplicationSummary>[],
      nextCursor: null,
    );
    await container
        .read(adminCleanerReviewControllerProvider.notifier)
        .loadMore();
    expect(api.lastAfter, equals('c2'));
    expect(
      container.read(adminCleanerReviewControllerProvider).nextCursor,
      isNull,
    );
  });

  test('detail, approve, and reject update state', () async {
    api.page = AdminCleanerApplicationPage(
      items: [summary()],
      nextCursor: null,
    );
    api.detail = AdminCleanerApplicationDetail(
      userId: '507f1f77bcf86cd799439077',
      email: 'pending.cleaner@example.com',
      profile: CleanerProfile.fromJson(cleanerProfileJson(status: 'pending')),
    );
    await settle();
    final notifier = container.read(
      adminCleanerReviewControllerProvider.notifier,
    );
    await notifier.loadDetail('507f1f77bcf86cd799439077');
    expect(
      container.read(adminCleanerReviewControllerProvider).detail?.email,
      equals('pending.cleaner@example.com'),
    );
    expect(await notifier.approve('507f1f77bcf86cd799439077'), isTrue);
    expect(api.approveCalls, equals(1));
    expect(container.read(adminCleanerReviewControllerProvider).items, isEmpty);
    expect(
      await notifier.reject('507f1f77bcf86cd799439077', 'Need more bio.'),
      isTrue,
    );
    expect(api.rejectCalls, equals(1));
  });

  test('safe error stays user-readable', () async {
    api.nextError = ApiFailure(
      code: 'cleaner_application_not_found',
      message: messageForApiCode('cleaner_application_not_found'),
    );
    final state = await settle();
    expect(state.errorMessage, equals('Cleaner application was not found.'));
  });
}
