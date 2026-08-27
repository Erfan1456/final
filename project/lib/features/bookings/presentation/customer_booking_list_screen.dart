import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_status_chip.dart';

class CustomerBookingListScreen extends ConsumerWidget {
  const CustomerBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerBookingControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.small,
                children: [
                  for (final option in bookingFilterOptions)
                    FilterChip(
                      label: Text(option.$1),
                      selected: state.statusFilter == option.$2,
                      onSelected: (_) {
                        ref
                            .read(customerBookingControllerProvider.notifier)
                            .load(
                              status: option.$2,
                              clearFilter: option.$2 == null,
                            );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.normal),
              if (state.errorMessage != null && state.items.isNotEmpty)
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Expanded(
                child: AppAsyncContent(
                  loading: state.loading,
                  hasData: state.items.isNotEmpty,
                  errorMessage: state.errorMessage,
                  onRetry: () => ref
                      .read(customerBookingControllerProvider.notifier)
                      .load(),
                  emptyTitle: 'No bookings yet.',
                  emptyMessage: 'Find a cleaner to create your first booking.',
                  emptyActionLabel: 'Find a Cleaner',
                  onEmptyAction: () =>
                      context.push(AppRoutes.customerDiscoverPath),
                  loadingMessage: 'Loading bookings...',
                  builder: (context) => ListView(
                    children: [
                      for (final booking in state.items)
                        Card(
                          child: ListTile(
                            title: Text(booking.cleanerFullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking.serviceSnapshot.name),
                                Text(formatLocalDateTime(booking.startAt)),
                                AppStatusChip(label: booking.status.label),
                                Text(
                                  formatQuotedTotal(
                                    booking.quotedTotalMinor,
                                    booking.currencyCode,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              context.push(
                                AppRoutes.customerBookingDetailLocation(
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
                                        customerBookingControllerProvider
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
