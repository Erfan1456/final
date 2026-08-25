import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';

class BookingPaymentSection extends ConsumerWidget {
  const BookingPaymentSection({super.key, required this.booking});

  final CustomerBooking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (booking.status != BookingStatus.confirmed) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(customerPaymentControllerProvider);
    final current = state.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment'),
        const SizedBox(height: 8),
        if (state.loading && current == null)
          const LinearProgressIndicator()
        else if (current == null) ...[
          const Text('No payment'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.push(
              AppRoutes.customerBookingPaymentLocation(booking.id),
            ),
            child: const Text('Pay Now'),
          ),
        ] else ...[
          Text(current.status.label),
          Text(formatPaymentAmount(current.amountMinor, current.currencyCode)),
          if (current.status == PaymentStatus.paid && current.paidAt != null)
            Text('Paid at ${current.paidAt!.toIso8601String()}'),
          if (current.status == PaymentStatus.partiallyRefunded) ...[
            Text(
              'Refunded: ${formatPaymentAmount(current.refundedAmountMinor, current.currencyCode)}',
            ),
          ],
          if (current.status == PaymentStatus.refunded)
            Text(
              'Refunded ${formatPaymentAmount(current.refundedAmountMinor, current.currencyCode)}',
            ),
          if (current.status == PaymentStatus.failed)
            const Text('Payment Failed'),
          if (current.status == PaymentStatus.pending)
            const Text('Payment Pending'),
          const SizedBox(height: 8),
          if (current.status.isPendingAttempt) ...[
            OutlinedButton(
              onPressed: state.submitting
                  ? null
                  : () => ref
                        .read(customerPaymentControllerProvider.notifier)
                        .cancelPayment(booking.id),
              child: const Text('Cancel Payment'),
            ),
          ],
          if (current.status.canRetry)
            FilledButton(
              onPressed: () => context.push(
                AppRoutes.customerBookingPaymentLocation(booking.id),
              ),
              child: const Text('Retry Payment'),
            ),
          if (current.status == PaymentStatus.paid ||
              current.status == PaymentStatus.partiallyRefunded ||
              current.status == PaymentStatus.refunded)
            TextButton(
              onPressed: () => context.push(
                AppRoutes.customerBookingPaymentLocation(booking.id),
              ),
              child: const Text('Payment details'),
            ),
          if (current.simulationAvailable) ...[
            const SizedBox(height: 8),
            const Text('Development Sandbox'),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: state.submitting
                      ? null
                      : () => ref
                            .read(customerPaymentControllerProvider.notifier)
                            .simulateSuccess(booking.id, current.id),
                  child: const Text('Simulate Success'),
                ),
                OutlinedButton(
                  onPressed: state.submitting
                      ? null
                      : () => ref
                            .read(customerPaymentControllerProvider.notifier)
                            .simulateFailure(booking.id, current.id),
                  child: const Text('Simulate Failure'),
                ),
              ],
            ),
          ],
        ],
        if (state.errorMessage != null) Text(state.errorMessage!),
      ],
    );
  }
}
