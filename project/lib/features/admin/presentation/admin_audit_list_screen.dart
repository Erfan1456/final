import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/data/audit_models.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_log_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';

class AdminAuditListScreen extends ConsumerWidget {
  const AdminAuditListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAuditLogControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All actions'),
                    selected: state.filters.action == null,
                    onSelected: (_) => ref
                        .read(adminAuditLogControllerProvider.notifier)
                        .applyFilters(
                          state.filters.copyWith(clearAction: true),
                        ),
                  ),
                  for (final action in AuditAction.filterable)
                    ChoiceChip(
                      label: Text(action.label),
                      selected: state.filters.action == action.wireValue,
                      onSelected: (_) => ref
                          .read(adminAuditLogControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(action: action.wireValue),
                          ),
                    ),
                  for (final type in <String>[
                    'user',
                    'booking',
                    'dispute',
                    'review',
                    'payment',
                    'cleaner_profile',
                  ])
                    ChoiceChip(
                      label: Text(type),
                      selected: state.filters.targetType == type,
                      onSelected: (_) => ref
                          .read(adminAuditLogControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              targetType: state.filters.targetType == type
                                  ? null
                                  : type,
                              clearTargetType: state.filters.targetType == type,
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
                            title: Text(item.action.label),
                            subtitle: Text(
                              '${formatLocalDateTime(item.createdAt)}\n'
                              'Actor ${item.actorUserId}\n'
                              '${item.targetType} ${item.targetId}',
                            ),
                            isThreeLine: true,
                            onTap: () => context.push(
                              AppRoutes.adminAuditLogDetailLocation(item.id),
                            ),
                          ),
                        if (state.nextCursor != null)
                          FilledButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => ref
                                      .read(
                                        adminAuditLogControllerProvider
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
