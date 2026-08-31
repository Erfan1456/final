import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_user_management_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminUserManagementControllerProvider.notifier)
          .loadDetail(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUserManagementControllerProvider);
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('User detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'User was not found.')
              : ListView(
                  children: [
                    Text(detail.user.email),
                    Text(detail.user.role),
                    Text(detail.user.accountStatus),
                    if (detail.customerProfile != null)
                      Text(detail.customerProfile!.fullName),
                    if (detail.cleanerProfile != null) ...[
                      Text(detail.cleanerProfile!.fullName),
                      Text(detail.cleanerProfile!.onboardingStatus.wireValue),
                    ],
                    Text('Bookings: ${detail.bookingCount}'),
                    if (detail.protectedAdminAccount) ...[
                      const SizedBox(height: 16),
                      const Text('Protected administrator account'),
                    ],
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    if (!detail.protectedAdminAccount) ...[
                      const SizedBox(height: 16),
                      if (detail.user.accountStatus == 'active')
                        FilledButton(
                          onPressed: state.saving
                              ? null
                              : () => _moderate(
                                  title: 'Suspend account',
                                  action: (reason) => ref
                                      .read(
                                        adminUserManagementControllerProvider
                                            .notifier,
                                      )
                                      .suspend(
                                        userId: detail.user.id,
                                        reason: reason,
                                      ),
                                ),
                          child: const Text('Suspend'),
                        ),
                      if (detail.user.accountStatus == 'suspended') ...[
                        FilledButton(
                          onPressed: state.saving
                              ? null
                              : () => ref
                                    .read(
                                      adminUserManagementControllerProvider
                                          .notifier,
                                    )
                                    .reactivate(detail.user.id),
                          child: const Text('Reactivate'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (detail.user.accountStatus != 'deactivated')
                        FilledButton(
                          onPressed: state.saving
                              ? null
                              : () => _moderate(
                                  title: 'Deactivate account',
                                  action: (reason) => ref
                                      .read(
                                        adminUserManagementControllerProvider
                                            .notifier,
                                      )
                                      .deactivate(
                                        userId: detail.user.id,
                                        reason: reason,
                                      ),
                                ),
                          child: const Text('Deactivate'),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _moderate({
    required String title,
    required Future<bool> Function(String reason) action,
  }) async {
    final prompt = await promptBookingReason(
      context,
      title: title,
      required: true,
    );
    if (!mounted || !prompt.submitted || prompt.reason == null) {
      return;
    }
    await action(prompt.reason!);
  }
}
