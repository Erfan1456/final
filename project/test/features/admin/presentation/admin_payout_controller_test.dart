import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_finance_models.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_payout_api.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_payout_controller.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeAdminPayoutApi extends AdminPayoutApi {
  _FakeAdminPayoutApi() : super(Dio());

  CleanerPayoutPage page = CleanerPayoutPage(
    items: [testCleanerPayout()],
    nextCursor: 'cursor-1',
  );
  AdminPayoutDetail detail = testAdminPayoutDetail();
  String? lastStatus;
  String? lastAfter;
  int listCalls = 0;
  int processCalls = 0;

  @override
  Future<CleanerPayoutPage> listPayouts({
    String? status,
    String? currency,
    String? cleanerUserId,
    int? limit,
    String? after,
  }) async {
    listCalls += 1;
    lastStatus = status;
    lastAfter = after;
    return page;
  }

  @override
  Future<AdminPayoutDetail> getPayout(String payoutId) async {
    return detail;
  }

  @override
  Future<CleanerPayout> process(String payoutId) async {
    processCalls += 1;
    return testCleanerPayout(status: 'processing');
  }

  @override
  Future<CleanerPayout> reject({
    required String payoutId,
    required String reason,
  }) async {
    return testCleanerPayout(status: 'rejected', rejectionReason: reason);
  }

  @override
  Future<CleanerPayout> simulateSuccess(String payoutId) async {
    return testCleanerPayout(status: 'paid', simulationAvailable: true);
  }

  @override
  Future<CleanerPayout> simulateFailure(String payoutId) async {
    return testCleanerPayout(status: 'failed', simulationAvailable: true);
  }
}

void main() {
  test('lists, filters, paginates, and processes payouts', () async {
    final api = _FakeAdminPayoutApi();
    final container = ProviderContainer(
      overrides: [adminPayoutApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final controller = container.read(adminPayoutControllerProvider.notifier);
    await controller.load();
    expect(api.lastStatus, equals('requested'));
    await controller.applyFilters(const AdminPayoutFilters(status: 'paid'));
    expect(api.lastStatus, equals('paid'));
    await controller.loadMore();
    expect(api.lastAfter, equals('cursor-1'));
    await controller.process('507f1f77bcf86cd7994390f1');
    expect(api.processCalls, equals(1));
  });
}
