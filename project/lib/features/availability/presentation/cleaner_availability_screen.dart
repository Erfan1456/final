import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/availability_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/presentation/catalog_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_date_time.dart';

export 'package:home_cleaning_marketplace/shared/presentation/app_date_time.dart'
    show formatLocalDateTime;

/// Future open availability slots for the authenticated cleaner.
class CleanerAvailabilityScreen extends ConsumerWidget {
  const CleanerAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved =
        ref
            .watch(cleanerOnboardingControllerProvider)
            .profile
            ?.onboardingStatus ==
        OnboardingStatus.approved;
    final state = ref.watch(availabilityControllerProvider);
    final catalog = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Availability')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: !approved
              ? const Text('Approval required')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          context.push(AppRoutes.cleanerAvailabilityNewPath),
                      child: const Text('Add Availability'),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(state.errorMessage!),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'New slots must start in the future, last 1–8 hours, '
                      'and use 30-minute steps.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: state.loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              children: [
                                for (final slot in state.slots)
                                  ListTile(
                                    title: Text(
                                      catalog.items
                                              .where(
                                                (s) => s.id == slot.serviceId,
                                              )
                                              .map((s) => s.name)
                                              .firstOrNull ??
                                          slot.serviceId,
                                    ),
                                    subtitle: Text(
                                      '${formatLocalDateTime(slot.startAt)} → '
                                      '${formatLocalDateTime(slot.endAt)} '
                                      '(${slot.duration.inMinutes} min)',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => context.push(
                                            AppRoutes
                                                .cleanerAvailabilityEditPath
                                                .replaceFirst(
                                                  ':slotId',
                                                  slot.id,
                                                ),
                                          ),
                                          icon: const Icon(Icons.edit),
                                        ),
                                        IconButton(
                                          onPressed: () => _confirmDelete(
                                            context,
                                            ref,
                                            slot.id,
                                          ),
                                          icon: const Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String slotId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete availability?'),
          content: const Text('This open slot will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(availabilityControllerProvider.notifier).delete(slotId);
    }
  }
}
