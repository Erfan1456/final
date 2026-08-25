import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_section.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

class CustomerBookingDetailScreen extends ConsumerStatefulWidget {
  const CustomerBookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<CustomerBookingDetailScreen> createState() =>
      _CustomerBookingDetailScreenState();
}

class _CustomerBookingDetailScreenState
    extends ConsumerState<CustomerBookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(customerBookingControllerProvider.notifier)
          .loadDetail(widget.bookingId);
      ref
          .read(customerPaymentControllerProvider.notifier)
          .load(widget.bookingId);
      ref
          .read(customerReviewControllerProvider.notifier)
          .load(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBookingControllerProvider);
    final booking = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && booking == null
              ? const Center(child: CircularProgressIndicator())
              : booking == null
              ? Text(state.errorMessage ?? 'Booking was not found.')
              : ListView(
                  children: [
                    Text(booking.status.label),
                    Text(booking.cleanerFullName),
                    Text(booking.serviceSnapshot.name),
                    Text(
                      '${formatLocalDateTime(booking.startAt)} → ${formatLocalDateTime(booking.endAt)}',
                    ),
                    Text('Duration: ${booking.durationMinutes} minutes'),
                    Text(
                      formatMinorHourlyRate(
                        booking.hourlyRateMinor,
                        booking.currencyCode,
                      ),
                    ),
                    Text(
                      formatQuotedTotal(
                        booking.quotedTotalMinor,
                        booking.currencyCode,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BookingAddressView(
                      address: booking.addressSnapshot,
                      fullAddressAllowed: true,
                    ),
                    if (booking.customerNotes != null) ...[
                      const SizedBox(height: 12),
                      Text('Notes: ${booking.customerNotes}'),
                    ],
                    const SizedBox(height: 16),
                    BookingPaymentSection(booking: booking),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.push(
                        AppRoutes.customerBookingChatLocation(booking.id),
                      ),
                      child: const Text('Message Cleaner'),
                    ),
                    if (booking.status == BookingStatus.completed) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.push(
                          AppRoutes.customerBookingReviewLocation(booking.id),
                        ),
                        child: Text(
                          ref.watch(customerReviewControllerProvider).review ==
                                  null
                              ? 'Leave Review'
                              : 'Edit Review',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    BookingStatusHistoryList(history: booking.statusHistory),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    if (booking.canCancel) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state.submitting
                            ? null
                            : () async {
                                final prompt = await promptBookingReason(
                                  context,
                                  title: 'Cancel Booking',
                                  required: false,
                                );
                                if (!context.mounted || !prompt.submitted) {
                                  return;
                                }
                                await ref
                                    .read(
                                      customerBookingControllerProvider
                                          .notifier,
                                    )
                                    .cancel(booking.id, reason: prompt.reason);
                              },
                        child: Text(
                          state.submitting ? 'Cancelling...' : 'Cancel Booking',
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
