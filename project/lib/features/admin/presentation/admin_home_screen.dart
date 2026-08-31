import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/logout_actions.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_home_link.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_section.dart';

/// Administrator dashboard with grouped operational sections.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Home')),
      body: SafeArea(
        child: AppLayout.constrained(
          maxWidth: AppLayout.dashboardMaxWidth,
          child: ListView(
            children: [
              Text('Signed in as ${user?.email ?? 'admin'}'),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'People & approvals',
                children: [
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.adminCleanersPath),
                    child: const Text('Approvals'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.adminUsersPath),
                    child: const Text('Users'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Marketplace operations',
                children: [
                  FilledButton.tonal(
                    onPressed: () => context.push(AppRoutes.adminBookingsPath),
                    child: const Text('Bookings'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.adminReviewsPath),
                    child: const Text('Review Moderation'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Audit',
                children: [
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.adminAuditLogsPath),
                    child: const Text('Audit Log'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Account',
                children: [
                  const NotificationHomeLink(),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.accountSecurityPath),
                    child: const Text('Security'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              const LogoutActions(),
            ],
          ),
        ),
      ),
    );
  }
}
