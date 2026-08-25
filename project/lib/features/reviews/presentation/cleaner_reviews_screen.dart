import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/cleaner_reviews_controller.dart';

class CleanerReviewsScreen extends ConsumerWidget {
  const CleanerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerReviewsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final option in <(String, String?)>[
                    ('All', null),
                    ('Published', 'published'),
                    ('Hidden', 'hidden'),
                  ])
                    ChoiceChip(
                      label: Text(option.$1),
                      selected: state.status == option.$2,
                      onSelected: (_) => ref
                          .read(cleanerReviewsControllerProvider.notifier)
                          .load(
                            status: option.$2,
                            clearStatus: option.$2 == null,
                          ),
                    ),
                ],
              ),
            ),
            if (state.errorMessage != null) Text(state.errorMessage!),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? const Center(child: Text('No reviews yet.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final item in state.items)
                          Card(
                            child: ListTile(
                              title: Text(
                                '${item.reviewerDisplayName} · ${item.rating} ★',
                              ),
                              subtitle: Text(
                                '${item.comment ?? ''}\n'
                                '${item.moderationStatus.label} · '
                                '${formatLocalDateTime(item.createdAt)}',
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        if (state.nextCursor != null)
                          FilledButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => ref
                                      .read(
                                        cleanerReviewsControllerProvider
                                            .notifier,
                                      )
                                      .loadMore(),
                            child: Text(
                              state.loadingMore ? 'Loading...' : 'Load More',
                            ),
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
