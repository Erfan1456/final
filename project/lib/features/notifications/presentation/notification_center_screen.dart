import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_models.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(notificationControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: state.saving
                ? null
                : () => ref
                      .read(notificationControllerProvider.notifier)
                      .markAll(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !state.unreadOnly,
                    onSelected: (_) => ref
                        .read(notificationControllerProvider.notifier)
                        .setUnreadFilter(false),
                  ),
                  ChoiceChip(
                    label: const Text('Unread'),
                    selected: state.unreadOnly,
                    onSelected: (_) => ref
                        .read(notificationControllerProvider.notifier)
                        .setUnreadFilter(true),
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null) Text(state.errorMessage!),
            Expanded(
              child: state.loading
                  ? const AppLoadingState(message: 'Loading notifications...')
                  : state.items.isEmpty
                  ? const AppEmptyState(
                      title: 'No notifications yet.',
                      message: 'Updates about bookings and account activity will appear here.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final item in state.items)
                          _NotificationTile(notification: item),
                        if (state.nextCursor != null)
                          FilledButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => ref
                                      .read(
                                        notificationControllerProvider.notifier,
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

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final InboxNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadStyle = notification.isRead
        ? null
        : Theme.of(context).textTheme.titleMedium;
    return Card(
      child: ListTile(
        title: Text(notification.title, style: unreadStyle),
        subtitle: Text(
          '${notification.body}\n${formatLocalDateTime(notification.createdAt)}',
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : TextButton(
                onPressed: () => ref
                    .read(notificationControllerProvider.notifier)
                    .markOne(notification.id),
                child: const Text('Mark read'),
              ),
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(notificationControllerProvider.notifier)
                .markOne(notification.id);
          }
          if (!context.mounted) {
            return;
          }
          final role = ref.read(authControllerProvider).user?.role ?? '';
          final location = notificationTargetLocation(notification, role);
          if (location == null) {
            return;
          }
          context.push(location);
        },
      ),
    );
  }
}

String? notificationTargetLocation(
  InboxNotification notification,
  String role,
) {
  final resourceType = notification.resourceType;
  final resourceId = notification.resourceId;
  if (resourceType == null || resourceType.isEmpty) {
    return null;
  }
  switch (resourceType) {
    case 'booking':
      if (resourceId == null || resourceId.isEmpty) {
        return null;
      }
      if (role == 'customer') {
        return AppRoutes.customerBookingDetailLocation(resourceId);
      }
      if (role == 'cleaner') {
        return AppRoutes.cleanerBookingDetailLocation(resourceId);
      }
      return null;
    case 'message':
      if (resourceId == null || resourceId.isEmpty) {
        return null;
      }
      if (role == 'customer') {
        return AppRoutes.customerBookingChatLocation(resourceId);
      }
      if (role == 'cleaner') {
        return AppRoutes.cleanerBookingChatLocation(resourceId);
      }
      return null;
    case 'payment':
      if (resourceId == null || resourceId.isEmpty) {
        return null;
      }
      if (role == 'customer') {
        return AppRoutes.customerBookingPaymentLocation(resourceId);
      }
      return null;
    case 'review':
      if (role == 'cleaner') {
        return AppRoutes.cleanerReviewsPath;
      }
      return null;
    case 'dispute':
      if (resourceId == null || resourceId.isEmpty) {
        return null;
      }
      if (role == 'customer') {
        return AppRoutes.customerBookingDisputeLocation(resourceId);
      }
      if (role == 'cleaner') {
        return AppRoutes.cleanerBookingDisputeLocation(resourceId);
      }
      return null;
    case 'payout':
      if (role == 'cleaner') {
        if (resourceId == null || resourceId.isEmpty) {
          return AppRoutes.cleanerPayoutsPath;
        }
        return AppRoutes.cleanerPayoutDetailLocation(resourceId);
      }
      return null;
    default:
      return null;
  }
}
