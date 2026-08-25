import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/commission_math.dart';
import 'package:test/test.dart';

void main() {
  group('CommissionMath', () {
    test('0 bps charges no fee', () {
      expect(
        CommissionMath.platformFeeMinor(grossMinor: 100000, commissionBps: 0),
        equals(0),
      );
      expect(
        CommissionMath.cleanerNetMinor(grossMinor: 100000, commissionBps: 0),
        equals(100000),
      );
    });

    test('500 bps is 5 percent', () {
      expect(
        CommissionMath.platformFeeMinor(grossMinor: 100000, commissionBps: 500),
        equals(5000),
      );
      expect(
        CommissionMath.cleanerNetMinor(grossMinor: 100000, commissionBps: 500),
        equals(95000),
      );
    });

    test('1500 bps is 15 percent', () {
      expect(
        CommissionMath.platformFeeMinor(
          grossMinor: 100000,
          commissionBps: 1500,
        ),
        equals(15000),
      );
      expect(
        CommissionMath.cleanerNetMinor(grossMinor: 100000, commissionBps: 1500),
        equals(85000),
      );
    });

    test('10000 bps is 100 percent', () {
      expect(
        CommissionMath.platformFeeMinor(
          grossMinor: 100000,
          commissionBps: 10000,
        ),
        equals(100000),
      );
      expect(
        CommissionMath.cleanerNetMinor(
          grossMinor: 100000,
          commissionBps: 10000,
        ),
        equals(0),
      );
    });

    test('round-half-up uses integer arithmetic only', () {
      // 1 * 1 bps + 5000 = 5001; 5001 ~/ 10000 = 0
      expect(
        CommissionMath.platformFeeMinor(grossMinor: 1, commissionBps: 1),
        equals(0),
      );
      // 5000 * 1 + 5000 = 10000; 10000 ~/ 10000 = 1
      expect(
        CommissionMath.platformFeeMinor(grossMinor: 5000, commissionBps: 1),
        equals(1),
      );
      // 4999 * 1 + 5000 = 9999; 9999 ~/ 10000 = 0
      expect(
        CommissionMath.platformFeeMinor(grossMinor: 4999, commissionBps: 1),
        equals(0),
      );
      const gross = 333;
      const bps = 1500;
      final fee = CommissionMath.platformFeeMinor(
        grossMinor: gross,
        commissionBps: bps,
      );
      expect(fee, equals((gross * bps + 5000) ~/ 10000));
      expect(
        CommissionMath.cleanerNetMinor(grossMinor: gross, commissionBps: bps),
        equals(gross - fee),
      );
    });
  });
}
