import 'dart:developer' as developer;

import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/data/earnings_ledger_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/commission_math.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_entry_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_ledger_entry.dart';
import 'package:home_cleaning_marketplace_api/src/features/earnings/domain/earnings_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/data/payment_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/domain/payment.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent idempotent earning and refund-adjustment settlement.
///
/// Payment and booking remain the operational source of truth. Ledger append
/// failures must not undo those transitions; callers should use the try*
/// helpers around primary operations.
class EarningsSettlementService {
  /// Creates a settlement service.
  EarningsSettlementService({
    required ServerConfig config,
    required BookingRepository bookings,
    required PaymentRepository payments,
    required EarningsLedgerRepository ledger,
    DateTime Function()? clock,
  }) : _config = config,
       _bookings = bookings,
       _payments = payments,
       _ledger = ledger,
       _clock = clock ?? DateTime.now;

  final ServerConfig _config;
  final BookingRepository _bookings;
  final PaymentRepository _payments;
  final EarningsLedgerRepository _ledger;
  final DateTime Function() _clock;

  /// Creates the original earning and any already-applied refund adjustments.
  ///
  /// No-ops when the booking is not completed or no successful payment exists.
  Future<void> ensureBookingEarning(ObjectId bookingId) async {
    if (!_config.hasValidPlatformCommissionBps) {
      developer.log(
        'Earnings settlement skipped: invalid PLATFORM_COMMISSION_BPS.',
        name: 'earnings',
      );
      return;
    }
    final booking = await _bookings.findById(bookingId);
    if (booking == null || booking.status != BookingStatus.completed) {
      return;
    }
    final payment = await _payments.findSuccessfulForBooking(bookingId);
    if (payment == null) {
      return;
    }
    await _ensureServiceEarning(booking: booking, payment: payment);
    await _ensureRefundCatchup(booking: booking, payment: payment);
  }

  /// Best-effort wrapper used by booking/payment primary operations.
  Future<void> tryEnsureBookingEarning(ObjectId bookingId) async {
    try {
      await ensureBookingEarning(bookingId);
    } catch (error, stackTrace) {
      developer.log(
        'Earnings settlement failed; reconciliation required.',
        name: 'earnings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Applies an incremental refund adjustment using the original commission.
  Future<void> applyRefundAdjustment({
    required ObjectId bookingId,
    required Payment payment,
    required int refundDeltaMinor,
    required String sourceEventKey,
  }) async {
    if (refundDeltaMinor < 1) {
      return;
    }
    final earning = await _ledger.findServiceEarningForBooking(bookingId);
    if (earning == null) {
      return;
    }
    final existingRefundGross = await _refundedGrossForBooking(bookingId);
    if (existingRefundGross >= payment.refundedAmountMinor) {
      return;
    }
    final remaining = payment.refundedAmountMinor - existingRefundGross;
    final delta = refundDeltaMinor < remaining ? refundDeltaMinor : remaining;
    if (delta < 1) {
      return;
    }
    await _appendRefundAdjustment(
      earning: earning,
      payment: payment,
      refundDeltaMinor: delta,
      sourceEventKey: sourceEventKey,
    );
  }

  /// Best-effort wrapper used by payment webhook refund application.
  Future<void> tryApplyRefundAdjustment({
    required ObjectId bookingId,
    required Payment payment,
    required int refundDeltaMinor,
    required String sourceEventKey,
  }) async {
    try {
      await applyRefundAdjustment(
        bookingId: bookingId,
        payment: payment,
        refundDeltaMinor: refundDeltaMinor,
        sourceEventKey: sourceEventKey,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Refund adjustment failed; reconciliation required.',
        name: 'earnings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _ensureServiceEarning({
    required Booking booking,
    required Payment payment,
  }) async {
    final sourceEventKey = EarningsValidation.serviceEarningSourceEventKey(
      booking.id,
    );
    final existing = await _ledger.findBySourceEventKey(sourceEventKey);
    if (existing != null) {
      return;
    }
    final commissionBps = _config.platformCommissionBps;
    final platformFee = CommissionMath.platformFeeMinor(
      grossMinor: payment.amountMinor,
      commissionBps: commissionBps,
    );
    final cleanerNet = payment.amountMinor - platformFee;
    final entry = EarningsLedgerEntry(
      id: ObjectId(),
      cleanerUserId: booking.cleanerUserId,
      bookingId: booking.id,
      paymentId: payment.id,
      entryType: EarningsEntryType.serviceEarning,
      grossAmountMinor: payment.amountMinor,
      commissionBps: commissionBps,
      platformFeeMinor: platformFee,
      cleanerAmountMinor: cleanerNet,
      currencyCode: payment.currencyCode,
      sourceEventKey: sourceEventKey,
      createdAt: _clock().toUtc(),
    );
    try {
      await _ledger.append(entry);
    } on EarningsDuplicateKeyException {
      await _ledger.findBySourceEventKey(sourceEventKey);
    }
  }

  Future<void> _ensureRefundCatchup({
    required Booking booking,
    required Payment payment,
  }) async {
    if (payment.refundedAmountMinor < 1) {
      return;
    }
    final earning = await _ledger.findServiceEarningForBooking(booking.id);
    if (earning == null) {
      return;
    }
    final existingRefundGross = await _refundedGrossForBooking(booking.id);
    final remaining = payment.refundedAmountMinor - existingRefundGross;
    if (remaining < 1) {
      return;
    }
    await _appendRefundAdjustment(
      earning: earning,
      payment: payment,
      refundDeltaMinor: remaining,
      sourceEventKey: EarningsValidation.refundCatchupSourceEventKey(
        payment.id,
      ),
    );
  }

  Future<void> _appendRefundAdjustment({
    required EarningsLedgerEntry earning,
    required Payment payment,
    required int refundDeltaMinor,
    required String sourceEventKey,
  }) async {
    final existing = await _ledger.findBySourceEventKey(sourceEventKey);
    if (existing != null) {
      return;
    }
    final platformFeeRefund = CommissionMath.platformFeeMinor(
      grossMinor: refundDeltaMinor,
      commissionBps: earning.commissionBps,
    );
    final cleanerRefund = refundDeltaMinor - platformFeeRefund;
    final entry = EarningsLedgerEntry(
      id: ObjectId(),
      cleanerUserId: earning.cleanerUserId,
      bookingId: earning.bookingId,
      paymentId: payment.id,
      entryType: EarningsEntryType.refundAdjustment,
      grossAmountMinor: -refundDeltaMinor,
      commissionBps: earning.commissionBps,
      platformFeeMinor: -platformFeeRefund,
      cleanerAmountMinor: -cleanerRefund,
      currencyCode: earning.currencyCode,
      sourceEventKey: sourceEventKey,
      createdAt: _clock().toUtc(),
    );
    try {
      await _ledger.append(entry);
    } on EarningsDuplicateKeyException {
      await _ledger.findBySourceEventKey(sourceEventKey);
    }
  }

  Future<int> _refundedGrossForBooking(ObjectId bookingId) async {
    final entries = await _ledger.listForBooking(bookingId);
    var total = 0;
    for (final entry in entries) {
      if (entry.entryType == EarningsEntryType.refundAdjustment) {
        total += -entry.grossAmountMinor;
      }
    }
    return total;
  }
}
