import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';

class CustomerPaymentScreen extends ConsumerStatefulWidget {
  const CustomerPaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<CustomerPaymentScreen> createState() =>
      _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends ConsumerState<CustomerPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(customerPaymentControllerProvider.notifier)
          .load(widget.bookingId);
      ref
          .read(customerBookingControllerProvider.notifier)
          .loadDetail(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(customerPaymentControllerProvider);
    final booking = ref.watch(customerBookingControllerProvider).detail;
    final current = paymentState.current;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: paymentState.loading && current == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (booking != null) ...[
                      Text(booking.serviceSnapshot.name),
                      Text(booking.cleanerFullName),
                      Text(
                        formatQuotedTotal(
                          booking.quotedTotalMinor,
                          booking.currencyCode,
                        ),
                      ),
                    ],
                    if (current != null) ...[
                      Text('Provider: ${current.provider.label}'),
                      Text('Status: ${current.status.label}'),
                      Text('Attempt ${current.attemptNumber}'),
                      Text(
                        formatPaymentAmount(
                          current.amountMinor,
                          current.currencyCode,
                        ),
                      ),
                    ],
                    if (paymentState.errorMessage != null)
                      Text(paymentState.errorMessage!),
                    const SizedBox(height: 16),
                    if (current == null || current.status.canRetry)
                      FilledButton(
                        onPressed: paymentState.submitting
                            ? null
                            : () async {
                                final notifier = ref.read(
                                  customerPaymentControllerProvider.notifier,
                                );
                                if (current?.status.canRetry == true) {
                                  await notifier.retryPayment(widget.bookingId);
                                } else {
                                  notifier.beginAttempt();
                                  await notifier.startPayment(widget.bookingId);
                                }
                              },
                        child: Text(
                          paymentState.submitting
                              ? 'Starting...'
                              : (current?.status.canRetry == true
                                    ? 'Retry Payment'
                                    : 'Start Payment'),
                        ),
                      ),
                    if (current != null && current.status.isPendingAttempt) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: paymentState.submitting
                            ? null
                            : () => ref
                                  .read(
                                    customerPaymentControllerProvider.notifier,
                                  )
                                  .cancelPayment(widget.bookingId),
                        child: const Text('Cancel Payment'),
                      ),
                    ],
                    if (current?.simulationAvailable == true) ...[
                      const SizedBox(height: 24),
                      const Text('Development Sandbox'),
                      const Text(
                        'This is not a real card processor and does not charge money.',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: paymentState.submitting
                            ? null
                            : () => ref
                                  .read(
                                    customerPaymentControllerProvider.notifier,
                                  )
                                  .simulateSuccess(
                                    widget.bookingId,
                                    current!.id,
                                  ),
                        child: const Text('Simulate Success'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: paymentState.submitting
                            ? null
                            : () => ref
                                  .read(
                                    customerPaymentControllerProvider.notifier,
                                  )
                                  .simulateFailure(
                                    widget.bookingId,
                                    current!.id,
                                  ),
                        child: const Text('Simulate Failure'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
