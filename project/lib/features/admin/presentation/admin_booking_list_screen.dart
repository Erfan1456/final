import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_booking_operations_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';

class AdminBookingListScreen extends ConsumerWidget {
  const AdminBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminBookingOperationsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in bookingFilterOptions)
                    ChoiceChip(
                      label: Text(option.$1),
                      selected: state.filters.status == option.$2?.wireValue,
                      onSelected: (_) => ref
                          .read(
                            adminBookingOperationsControllerProvider.notifier,
                          )
                          .applyFilters(
                            state.filters.copyWith(
                              status: option.$2?.wireValue,
                              clearStatus: option.$2 == null,
                            ),
                          ),
                    ),
                ],
              ),
            ),
            if (state.errorMessage != null) Text(state.errorMessage!),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final item in state.items)
                          ListTile(
                            title: Text(
                              '${item.status.label} · ${item.serviceName}',
                            ),
                            subtitle: Text(
                              '${item.customerDisplayName} / ${item.cleanerPublicName}\n'
                              '${formatLocalDateTime(item.startAt)}\n'
                              '${formatQuotedTotal(item.quotedTotalMinor, item.currencyCode)}'
                              '${item.payment == null ? '' : ' · ${item.payment!.status.label}'}'
                              '${item.dispute == null ? '' : ' · ${item.dispute!.status.label}'}',
                            ),
                            isThreeLine: true,
                            onTap: () => context.push(
                              AppRoutes.adminBookingDetailLocation(item.id),
                            ),
                          ),
                        if (state.nextCursor != null)
                          FilledButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => ref
                                      .read(
                                        adminBookingOperationsControllerProvider
                                            .notifier,
                                      )
                                      .loadMore(),
                            child: const Text('Load More'),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
