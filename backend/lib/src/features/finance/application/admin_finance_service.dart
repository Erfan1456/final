import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_ledger_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/cleaner_payout_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/data/payout_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/domain/payout_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Read-only administrator finance summary and reconciliation detection.
class AdminFinanceService {
  /// Creates an admin finance service.
  AdminFinanceService({
    required EarningsLedgerRepository ledger,
    required PayoutRepository payouts,
    required BookingRepository bookings,
    required PaymentRepository payments,
    required CleanerPayoutService cleanerPayouts,
    required CleanerProfileRepository cleanerProfiles,
    required UserRepository users,
    DateTime Function()? clock,
  }) : _ledger = ledger,
       _payouts = payouts,
       _bookings = bookings,
       _payments = payments,
       _cleanerPayouts = cleanerPayouts,
       _cleanerProfiles = cleanerProfiles,
       _users = users,
       _clock = clock ?? DateTime.now;

  final EarningsLedgerRepository _ledger;
  final PayoutRepository _payouts;
  final BookingRepository _bookings;
  final PaymentRepository _payments;
  final CleanerPayoutService _cleanerPayouts;
  final CleanerProfileRepository _cleanerProfiles;
  final UserRepository _users;
  final DateTime Function() _clock;

  /// Per-currency finance summary. Does not label platform fees as profit.
  Future<Map<String, Object?>> summary({
    Object? fromRaw,
    Object? toRaw,
    Object? currency,
  }) async {
    final range = PayoutValidation.requireFinanceRange(
      fromRaw: fromRaw,
      toRaw: toRaw,
      now: _clock(),
    );
    final currencyCode = PayoutValidation.optionalCurrency(currency);
    final ledger = await _ledger.aggregateAdminFinanceSummary(
      from: range.from,
      to: range.to,
      currencyCode: currencyCode,
    );
    final payouts = await _payouts.aggregateAdminFinanceTotals(
      from: range.from,
      to: range.to,
      currencyCode: currencyCode,
    );
    final currencies = <String>{...ledger.keys, ...payouts.keys}.toList()
      ..sort();
    return <String, Object?>{
      'from': range.from.toIso8601String(),
      'to': range.to.toIso8601String(),
      'currencies': [
        for (final code in currencies)
          <String, Object?>{
            'currency_code': code,
            'gross_service_volume_minor':
                ledger[code]?.grossServiceVolumeMinor ?? 0,
            'platform_fee_minor': ledger[code]?.platformFeeMinor ?? 0,
            'cleaner_net_earnings_minor':
                ledger[code]?.cleanerNetEarningsMinor ?? 0,
            'refund_gross_minor': ledger[code]?.refundGrossMinor ?? 0,
            'cleaner_refund_adjustments_minor':
                ledger[code]?.cleanerRefundAdjustmentsMinor ?? 0,
            'payout_requested_minor': payouts[code]?.requestedMinor ?? 0,
            'payout_processing_minor': payouts[code]?.processingMinor ?? 0,
            'payout_paid_minor': payouts[code]?.paidMinor ?? 0,
            'payout_failed_minor': payouts[code]?.failedMinor ?? 0,
          },
      ],
    };
  }

  /// Read-only cleaner financial detail.
  Future<Map<String, Object?>> cleanerFinance(ObjectId userId) async {
    final user = await _users.findById(userId);
    if (user == null || user.role != UserRole.cleaner) {
      throw const UserNotFoundException();
    }
    final profile = await _cleanerProfiles.findByUserId(userId);
    final summaries = await _cleanerPayouts.currencySummaries(userId);
    final ledger = await _ledger.listForCleaner(
      cleanerUserId: userId,
      limit: 20,
    );
    final payouts = await _payouts.listForCleaner(
      cleanerUserId: userId,
      limit: 20,
    );
    return <String, Object?>{
      'cleaner_user_id': userId.oid,
      'cleaner_display_name': profile?.fullName ?? 'Cleaner',
      'currencies': [for (final item in summaries) item.toJson()],
      'recent_ledger': [
        for (final item in ledger.items) item.toPublicJson(),
      ],
      'recent_payouts': [
        for (final item in payouts.items) item.toAdminJson(),
      ],
    };
  }

  /// Read-only detection of missing earnings and refund-adjustment mismatches.
  Future<Map<String, Object?>> reconciliation({
    Object? currency,
    Object? limitRaw,
    Object? after,
  }) async {
    final currencyCode = PayoutValidation.optionalCurrency(currency);
    final limit = PayoutValidation.requireLimit(limitRaw);
    final cursor = PayoutValidation.optionalCursor(after);
    final page = await _bookings.adminPage(
      limit: limit,
      status: BookingStatus.completed,
      after: cursor,
    );
    final issues = <Map<String, Object?>>[];
    for (final booking in page.items) {
      final payment = await _payments.findSuccessfulForBooking(booking.id);
      if (payment == null) {
        continue;
      }
      if (currencyCode != null && payment.currencyCode != currencyCode) {
        continue;
      }
      final earning = await _ledger.findServiceEarningForBooking(booking.id);
      if (earning == null) {
        issues.add(<String, Object?>{
          'issue_type': 'missing_service_earning',
          'booking_id': booking.id.oid,
          'payment_id': payment.id.oid,
          'currency_code': payment.currencyCode,
          'explanation':
              'Completed booking with a successful payment has no '
              'service earning.',
        });
        continue;
      }
      final entries = await _ledger.listForBooking(booking.id);
      var refundedGross = 0;
      for (final entry in entries) {
        if (entry.entryType == EarningsEntryType.refundAdjustment) {
          refundedGross += -entry.grossAmountMinor;
        }
      }
      if (refundedGross != payment.refundedAmountMinor) {
        issues.add(<String, Object?>{
          'issue_type': 'refund_adjustment_mismatch',
          'booking_id': booking.id.oid,
          'payment_id': payment.id.oid,
          'currency_code': payment.currencyCode,
          'explanation':
              'Refund adjustments do not match the payment refunded amount.',
        });
      }
    }
    return <String, Object?>{
      'items': issues,
      'next_cursor': page.nextCursor,
    };
  }
}
