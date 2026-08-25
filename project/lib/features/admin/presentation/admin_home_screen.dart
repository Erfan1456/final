import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/logout_actions.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_home_link.dart';

/// Administrator dashboard.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(user?.email ?? ''),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminCleanersPath),
              child: const Text('Cleaner Approvals'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminPaymentsPath),
              child: const Text('Payments'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminReviewsPath),
              child: const Text('Review Moderation'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminDisputesPath),
              child: const Text('Disputes'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminUsersPath),
              child: const Text('Users'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminBookingsPath),
              child: const Text('Bookings'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(AppRoutes.adminAuditLogsPath),
              child: const Text('Audit Log'),
            ),
            const SizedBox(height: 12),
            const NotificationHomeLink(),
            const SizedBox(height: 24),
            const LogoutActions(),
          ],
        ),
      ),
    );
  }
}
