import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_controller.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';

class AdminDisputeListScreen extends ConsumerWidget {
  const AdminDisputeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDisputeControllerProvider);
    final emptyTitle =
        state.filters.status == null ||
            state.filters.status == 'open' ||
            state.filters.status == 'under_review'
        ? 'No open disputes.'
        : 'No disputes.';
    return Scaffold(
      appBar: AppBar(title: const Text('Disputes')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in <(String, String?)>[
                    ('Open', 'open'),
                    ('Under review', 'under_review'),
                    ('Resolved', 'resolved'),
                    ('Closed', 'closed'),
                    ('All', null),
                  ])
                    ChoiceChip(
                      label: Text(option.$1),
                      selected: state.filters.status == option.$2,
                      onSelected: (_) => ref
                          .read(adminDisputeControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              status: option.$2,
                              clearStatus: option.$2 == null,
                            ),
                          ),
                    ),
                  for (final category in DisputeCategory.selectable)
                    ChoiceChip(
                      label: Text(category.label),
                      selected: state.filters.category == category.wireValue,
                      onSelected: (_) => ref
                          .read(adminDisputeControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              category:
                                  state.filters.category == category.wireValue
                                  ? null
                                  : category.wireValue,
                              clearCategory:
                                  state.filters.category == category.wireValue,
                            ),
                          ),
                    ),
                ],
              ),
            ),
            if (state.errorMessage != null && state.items.isNotEmpty)
              Text(state.errorMessage!),
            Expanded(
              child: AppAsyncContent(
                loading: state.loading,
                hasData: state.items.isNotEmpty,
                errorMessage: state.errorMessage,
                onRetry: () =>
                    ref.read(adminDisputeControllerProvider.notifier).load(),
                emptyTitle: emptyTitle,
                builder: (context) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final item in state.items)
                      ListTile(
                        title: Text(
                          '${item.status.label} · ${item.category.label}',
                        ),
                        subtitle: Text(
                          '${item.subject}\n'
                          'Booking ${item.bookingId}\n'
                          '${item.customerDisplayName} / ${item.cleanerPublicName}\n'
                          '${formatLocalDateTime(item.createdAt)}',
                        ),
                        isThreeLine: true,
                        onTap: () => context.push(
                          AppRoutes.adminDisputeDetailLocation(item.id),
                        ),
                      ),
                    if (state.nextCursor != null)
                      FilledButton(
                        onPressed: state.loadingMore
                            ? null
                            : () => ref
                                  .read(adminDisputeControllerProvider.notifier)
                                  .loadMore(),
                        child: const Text('Load More'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
