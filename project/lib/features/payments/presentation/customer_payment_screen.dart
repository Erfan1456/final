import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/customer_payment_controller.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_section.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_status_chip.dart';

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
        child: AppLayout.constrained(
          maxWidth: AppLayout.formMaxWidth,
          child: paymentState.loading && current == null
              ? const AppLoadingState(message: 'Loading payment...')
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
                      const SizedBox(height: AppSpacing.small),
                      Text('Provider: ${current.provider.label}'),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.small,
                        children: [
                          const Text('Status: '),
                          AppStatusChip(label: current.status.label),
                        ],
                      ),
                      Text('Attempt ${current.attemptNumber}'),
                      Text(
                        formatPaymentAmount(
                          current.amountMinor,
                          current.currencyCode,
                        ),
                      ),
                    ],
                    if (paymentState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.normal),
                        child: Text(
                          paymentState.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.normal),
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
                      const SizedBox(height: AppSpacing.small),
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
                      const SizedBox(height: AppSpacing.section),
                      const AppDevelopmentBanner(
                        message:
                            'Development Sandbox — not a real card processor '
                            'and does not charge money.',
                      ),
                      const SizedBox(height: AppSpacing.small),
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
                      const SizedBox(height: AppSpacing.small),
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
