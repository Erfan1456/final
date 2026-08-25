import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_controller.dart';

class NotificationHomeLink extends ConsumerStatefulWidget {
  const NotificationHomeLink({super.key});

  @override
  ConsumerState<NotificationHomeLink> createState() =>
      _NotificationHomeLinkState();
}

class _NotificationHomeLinkState extends ConsumerState<NotificationHomeLink> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(notificationControllerProvider.notifier).refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(
      notificationControllerProvider.select((state) => state.unreadCount),
    );
    return FilledButton.tonal(
      onPressed: () => context.push(AppRoutes.notificationsPath),
      child: Text(
        unreadCount > 0 ? 'Notifications ($unreadCount)' : 'Notifications',
      ),
    );
  }
}
