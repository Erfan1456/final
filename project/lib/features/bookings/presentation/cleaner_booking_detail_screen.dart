import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';

class CleanerBookingDetailScreen extends ConsumerStatefulWidget {
  const CleanerBookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<CleanerBookingDetailScreen> createState() =>
      _CleanerBookingDetailScreenState();
}

class _CleanerBookingDetailScreenState
    extends ConsumerState<CleanerBookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(cleanerBookingControllerProvider.notifier)
          .loadDetail(widget.bookingId);
    });
  }

  Future<void> _requireReason(
    String title,
    Future<bool> Function(String reason) action,
  ) async {
    final prompt = await promptBookingReason(
      context,
      title: title,
      required: true,
    );
    if (!mounted || !prompt.submitted) {
      return;
    }
    final reason = prompt.reason;
    if (reason == null || reason.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason of at least 5 characters.'),
        ),
      );
      return;
    }
    await action(reason);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerBookingControllerProvider);
    final booking = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
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
                    Text(booking.customerDisplayName),
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
                      fullAddressAllowed:
                          booking.status.exposesFullAddressToCleaner,
                    ),
                    if (booking.customerNotes != null) ...[
                      const SizedBox(height: 12),
                      Text('Notes: ${booking.customerNotes}'),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.push(
                        AppRoutes.cleanerBookingChatLocation(booking.id),
                      ),
                      child: const Text('Message Customer'),
                    ),
                    const SizedBox(height: 16),
                    BookingStatusHistoryList(history: booking.statusHistory),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    const SizedBox(height: 16),
                    if (booking.canAccept)
                      FilledButton(
                        onPressed: state.mutating
                            ? null
                            : () {
                                ref
                                    .read(
                                      cleanerBookingControllerProvider.notifier,
                                    )
                                    .accept(booking.id);
                              },
                        child: const Text('Accept'),
                      ),
                    if (booking.canDecline) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: state.mutating
                            ? null
                            : () {
                                _requireReason(
                                  'Decline booking',
                                  (reason) => ref
                                      .read(
                                        cleanerBookingControllerProvider
                                            .notifier,
                                      )
                                      .decline(booking.id, reason: reason),
                                );
                              },
                        child: const Text('Decline'),
                      ),
                    ],
                    if (booking.canCancel) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: state.mutating
                            ? null
                            : () {
                                _requireReason(
                                  'Cancel booking',
                                  (reason) => ref
                                      .read(
                                        cleanerBookingControllerProvider
                                            .notifier,
                                      )
                                      .cancel(booking.id, reason: reason),
                                );
                              },
                        child: const Text('Cancel'),
                      ),
                    ],
                    if (booking.canStart) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: state.mutating
                            ? null
                            : () {
                                ref
                                    .read(
                                      cleanerBookingControllerProvider.notifier,
                                    )
                                    .start(booking.id);
                              },
                        child: const Text('Start Job'),
                      ),
                    ],
                    if (booking.canComplete) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: state.mutating
                            ? null
                            : () {
                                ref
                                    .read(
                                      cleanerBookingControllerProvider.notifier,
                                    )
                                    .complete(booking.id);
                              },
                        child: const Text('Complete Job'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
