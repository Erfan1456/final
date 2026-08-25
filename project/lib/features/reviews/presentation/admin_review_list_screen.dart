import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_controller.dart';

class AdminReviewListScreen extends ConsumerWidget {
  const AdminReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReviewControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Moderation')),
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
                    ('All', null),
                    ('Published', 'published'),
                    ('Hidden', 'hidden'),
                  ])
                    ChoiceChip(
                      label: Text(option.$1),
                      selected: state.filters.status == option.$2,
                      onSelected: (_) => ref
                          .read(adminReviewControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              status: option.$2,
                              clearStatus: option.$2 == null,
                            ),
                          ),
                    ),
                  for (final rating in <int?>[null, 1, 2, 3, 4, 5])
                    ChoiceChip(
                      label: Text(rating == null ? 'Any rating' : '$rating ★'),
                      selected: state.filters.rating == rating,
                      onSelected: (_) => ref
                          .read(adminReviewControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              rating: rating,
                              clearRating: rating == null,
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
                              '${item.shortId} · ${item.rating} ★ · ${item.moderationStatus.label}',
                            ),
                            subtitle: Text(
                              'Booking ${item.bookingId}\n'
                              '${item.comment ?? ''}',
                            ),
                            isThreeLine: true,
                            onTap: () => context.push(
                              AppRoutes.adminReviewDetailLocation(item.id),
                            ),
                          ),
                        if (state.nextCursor != null)
                          FilledButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => ref
                                      .read(
                                        adminReviewControllerProvider.notifier,
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
