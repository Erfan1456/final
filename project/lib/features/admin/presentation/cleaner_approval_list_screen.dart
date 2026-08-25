import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';

/// Administrator cleaner approval queue.
class CleanerApprovalListScreen extends ConsumerWidget {
  const CleanerApprovalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminCleanerReviewControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cleaner approvals')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final status in <String>[
                    'pending',
                    'approved',
                    'rejected',
                  ])
                    ChoiceChip(
                      label: Text(
                        status[0].toUpperCase() + status.substring(1),
                      ),
                      selected: state.statusFilter == status,
                      onSelected: (_) => ref
                          .read(adminCleanerReviewControllerProvider.notifier)
                          .load(status: status),
                    ),
                ],
              ),
            ),
            if (state.errorMessage != null) Text(state.errorMessage!),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final item in state.items)
                    ListTile(
                      title: Text(item.fullName),
                      subtitle: Text(
                        '${item.email}\n${item.onboardingStatus.wireValue}'
                        '${item.submittedAt == null ? '' : '\n${item.submittedAt!.toIso8601String()}'}',
                      ),
                      isThreeLine: true,
                      onTap: () =>
                          context.push('/admin/cleaners/${item.userId}'),
                    ),
                  if (state.nextCursor != null)
                    FilledButton(
                      onPressed: state.loading
                          ? null
                          : () => ref
                                .read(
                                  adminCleanerReviewControllerProvider.notifier,
                                )
                                .loadMore(),
                      child: const Text('Load More'),
                    ),
                  if (state.loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
