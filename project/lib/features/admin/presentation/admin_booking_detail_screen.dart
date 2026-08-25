import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_operations_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';

class AdminBookingDetailScreen extends ConsumerStatefulWidget {
  const AdminBookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState
    extends ConsumerState<AdminBookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminBookingOperationsControllerProvider.notifier)
          .loadDetail(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBookingOperationsControllerProvider);
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking operations')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Booking was not found.')
              : ListView(
                  children: [
                    Text(detail.booking.status.label),
                    Text(detail.booking.serviceSnapshot.name),
                    Text(
                      '${detail.booking.customerDisplayName} / ${detail.booking.cleanerPublicName}',
                    ),
                    Text(
                      '${formatLocalDateTime(detail.booking.startAt)} → ${formatLocalDateTime(detail.booking.endAt)}',
                    ),
                    Text(
                      formatMinorHourlyRate(
                        detail.booking.hourlyRateMinor,
                        detail.booking.currencyCode,
                      ),
                    ),
                    Text(
                      formatQuotedTotal(
                        detail.booking.quotedTotalMinor,
                        detail.booking.currencyCode,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BookingAddressView(
                      address: detail.booking.addressSnapshot,
                      fullAddressAllowed: true,
                    ),
                    if (detail.booking.customerNotes != null)
                      Text('Notes: ${detail.booking.customerNotes}'),
                    const SizedBox(height: 16),
                    const Text('Payment summary'),
                    if (detail.payments.isEmpty) const Text('No payment yet.'),
                    for (final payment in detail.payments)
                      Text(
                        '${payment.status.label} · ${payment.currencyCode} ${payment.amountMinor}'
                        '${payment.refundedAmountMinor == 0 ? '' : ' · refunded ${payment.refundedAmountMinor}'}',
                      ),
                    if (detail.dispute != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Dispute: ${detail.dispute!.status.label} · ${detail.dispute!.category.label}',
                      ),
                    ],
                    const SizedBox(height: 16),
                    BookingStatusHistoryList(
                      history: detail.booking.statusHistory,
                    ),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    if (detail.canCancel) ...[
                      const SizedBox(height: 16),
                      if (detail.paidCancelWarning)
                        const Text(
                          'This paid booking requires a refund before cancellation. The server remains authoritative.',
                        ),
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () async {
                                final prompt = await promptBookingReason(
                                  context,
                                  title: 'Cancel Booking',
                                  required: true,
                                );
                                if (!context.mounted ||
                                    !prompt.submitted ||
                                    prompt.reason == null) {
                                  return;
                                }
                                await ref
                                    .read(
                                      adminBookingOperationsControllerProvider
                                          .notifier,
                                    )
                                    .cancel(
                                      bookingId: detail.booking.id,
                                      reason: prompt.reason!,
                                    );
                              },
                        child: Text(
                          state.saving ? 'Cancelling...' : 'Cancel Booking',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
