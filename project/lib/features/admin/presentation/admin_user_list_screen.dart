import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_management_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';

class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  ConsumerState<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUserManagementControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in <(String, String?)>[
                        ('All roles', null),
                        ('Customer', 'customer'),
                        ('Cleaner', 'cleaner'),
                        ('Admin', 'admin'),
                      ])
                        ChoiceChip(
                          label: Text(option.$1),
                          selected: state.filters.role == option.$2,
                          onSelected: (_) => ref
                              .read(
                                adminUserManagementControllerProvider.notifier,
                              )
                              .applyFilters(
                                state.filters.copyWith(
                                  role: option.$2,
                                  clearRole: option.$2 == null,
                                ),
                              ),
                        ),
                      for (final option in <(String, String?)>[
                        ('All statuses', null),
                        ('Active', 'active'),
                        ('Suspended', 'suspended'),
                        ('Deactivated', 'deactivated'),
                      ])
                        ChoiceChip(
                          label: Text(option.$1),
                          selected: state.filters.status == option.$2,
                          onSelected: (_) => ref
                              .read(
                                adminUserManagementControllerProvider.notifier,
                              )
                              .applyFilters(
                                state.filters.copyWith(
                                  status: option.$2,
                                  clearStatus: option.$2 == null,
                                ),
                              ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Exact email search',
                    ),
                    onSubmitted: (value) => ref
                        .read(adminUserManagementControllerProvider.notifier)
                        .applyFilters(
                          state.filters.copyWith(
                            email: value.trim().isEmpty ? null : value.trim(),
                            clearEmail: value.trim().isEmpty,
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
                            title: Text(item.email),
                            subtitle: Text(
                              '${item.role} · ${item.accountStatus}'
                              '${item.fullName == null ? '' : ' · ${item.fullName}'}'
                              '\n${formatLocalDateTime(item.createdAt)}',
                            ),
                            isThreeLine: true,
                            onTap: () => context.push(
                              AppRoutes.adminUserDetailLocation(item.id),
                            ),
                          ),
                        if (state.nextCursor != null)
                          FilledButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => ref
                                      .read(
                                        adminUserManagementControllerProvider
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
