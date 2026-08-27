import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_date_time.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_money.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_status_labels.dart';

void main() {
  group('formatAppDateTime / formatLocalDateTime', () {
    test('formats UTC DateTime into local display with month name', () {
      final utc = DateTime.utc(2026, 3, 15, 14, 5);
      final formatted = formatAppDateTime(utc);
      final local = utc.toLocal();

      expect(formatted, contains('15'));
      expect(formatted, contains('Mar'));
      expect(formatted, contains('2026'));
      expect(formatted, contains(local.minute.toString().padLeft(2, '0')));
      expect(formatted.contains('AM') || formatted.contains('PM'), isTrue);
      expect(formatLocalDateTime(utc), equals(formatted));
    });

    test('null DateTime returns em dash', () {
      expect(formatAppDateTime(null), equals('—'));
    });
  });

  group('money formatters', () {
    test('formatMinorUnits keeps integer minor units without /100', () {
      expect(formatMinorUnits(250000, 'BDT'), equals('BDT 250000 minor units'));
      expect(formatMinorUnits(250000, 'BDT'), isNot(contains('.')));
      expect(formatMinorUnits(99, 'USD'), equals('USD 99 minor units'));
    });

    test('formatPaymentAmount aliases formatMinorUnits', () {
      expect(
        formatPaymentAmount(1500, 'BDT'),
        equals(formatMinorUnits(1500, 'BDT')),
      );
    });

    test('formatQuotedTotal prefixes Quoted total', () {
      expect(
        formatQuotedTotal(4200, 'BDT'),
        equals('Quoted total: BDT 4200 minor units'),
      );
    });

    test('empty currency code falls back to XXX', () {
      expect(formatMinorUnits(10, '  '), equals('XXX 10 minor units'));
    });
  });

  group('AppStatusLabels', () {
    test('booking labels', () {
      expect(AppStatusLabels.booking('pending'), 'Pending');
      expect(AppStatusLabels.booking('confirmed'), 'Confirmed');
      expect(AppStatusLabels.booking('in_progress'), 'In Progress');
      expect(AppStatusLabels.booking('completed'), 'Completed');
      expect(AppStatusLabels.booking('declined'), 'Declined');
      expect(AppStatusLabels.booking('cancelled'), 'Cancelled');
      expect(AppStatusLabels.booking(null), AppStatusLabels.unknown);
      expect(AppStatusLabels.booking(''), AppStatusLabels.unknown);
      expect(AppStatusLabels.booking('weird'), AppStatusLabels.unsupported);
    });

    test('payment labels', () {
      expect(AppStatusLabels.payment('pending'), 'Pending');
      expect(AppStatusLabels.payment('authorized'), 'Authorized');
      expect(AppStatusLabels.payment('paid'), 'Paid');
      expect(AppStatusLabels.payment('failed'), 'Failed');
      expect(AppStatusLabels.payment('cancelled'), 'Cancelled');
      expect(
        AppStatusLabels.payment('partially_refunded'),
        'Partially Refunded',
      );
      expect(AppStatusLabels.payment('refunded'), 'Refunded');
      expect(AppStatusLabels.payment(null), AppStatusLabels.unknown);
      expect(AppStatusLabels.payment('nope'), AppStatusLabels.unsupported);
    });

    test('payout labels', () {
      expect(AppStatusLabels.payout('requested'), 'Requested');
      expect(AppStatusLabels.payout('processing'), 'Processing');
      expect(AppStatusLabels.payout('paid'), 'Paid');
      expect(AppStatusLabels.payout('failed'), 'Failed');
      expect(AppStatusLabels.payout('cancelled'), 'Cancelled');
      expect(AppStatusLabels.payout('rejected'), 'Rejected');
      expect(AppStatusLabels.payout(null), AppStatusLabels.unknown);
      expect(AppStatusLabels.payout('x'), AppStatusLabels.unsupported);
    });

    test('dispute labels', () {
      expect(AppStatusLabels.dispute('open'), 'Open');
      expect(AppStatusLabels.dispute('under_review'), 'Under Review');
      expect(AppStatusLabels.dispute('resolved'), 'Resolved');
      expect(AppStatusLabels.dispute('closed'), 'Closed');
      expect(AppStatusLabels.dispute(null), AppStatusLabels.unknown);
      expect(AppStatusLabels.dispute('x'), AppStatusLabels.unsupported);
    });

    test('review labels', () {
      expect(AppStatusLabels.review('published'), 'Published');
      expect(AppStatusLabels.review('hidden'), 'Hidden');
      expect(AppStatusLabels.review(null), AppStatusLabels.unknown);
      expect(AppStatusLabels.review('x'), AppStatusLabels.unsupported);
    });

    test('onboarding labels', () {
      expect(AppStatusLabels.onboarding('draft'), 'Draft');
      expect(AppStatusLabels.onboarding('pending'), 'Pending review');
      expect(AppStatusLabels.onboarding('approved'), 'Approved');
      expect(AppStatusLabels.onboarding('rejected'), 'Rejected');
      expect(AppStatusLabels.onboarding(null), AppStatusLabels.unknown);
      expect(AppStatusLabels.onboarding('x'), AppStatusLabels.unsupported);
    });
  });
}
