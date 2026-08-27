import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/cleaner_booking_controller.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';

class CleanerBookingListScreen extends ConsumerWidget {
  const CleanerBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerBookingControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests / Jobs')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final option in bookingFilterOptions)
                    FilterChip(
                      label: Text(option.$1),
                      selected: state.statusFilter == option.$2,
                      onSelected: (_) {
                        ref
                            .read(cleanerBookingControllerProvider.notifier)
                            .load(
                              status: option.$2,
                              clearFilter: option.$2 == null,
                            );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null && state.items.isNotEmpty)
                Text(state.errorMessage!),
              Expanded(
                child: AppAsyncContent(
                  loading: state.loading,
                  hasData: state.items.isNotEmpty,
                  errorMessage: state.errorMessage,
                  onRetry: () => ref
                      .read(cleanerBookingControllerProvider.notifier)
                      .load(),
                  emptyTitle: 'No booking requests right now.',
                  builder: (context) => ListView(
                    children: [
                      for (final booking in state.items)
                        Card(
                          child: ListTile(
                            title: Text(
                              booking.status == BookingStatus.pending
                                  ? '${booking.customerDisplayName} · Booking request'
                                  : booking.customerDisplayName,
                            ),
                            subtitle: Text(
                              '${booking.serviceSnapshot.name}\n'
                              '${formatLocalDateTime(booking.startAt)}\n'
                              '${booking.status.label} · ${booking.addressSnapshot.city}, ${booking.addressSnapshot.region}\n'
                              '${formatQuotedTotal(booking.quotedTotalMinor, booking.currencyCode)}',
                            ),
                            isThreeLine: true,
                            onTap: () {
                              context.push(
                                AppRoutes.cleanerBookingDetailLocation(
                                  booking.id,
                                ),
                              );
                            },
                          ),
                        ),
                      if (state.nextCursor != null)
                        TextButton(
                          onPressed: state.loadingMore
                              ? null
                              : () {
                                  ref
                                      .read(
                                        cleanerBookingControllerProvider
                                            .notifier,
                                      )
                                      .loadMore();
                                },
                          child: Text(
                            state.loadingMore ? 'Loading...' : 'Load More',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
