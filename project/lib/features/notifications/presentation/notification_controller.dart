import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_identity.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_api.dart';
import 'package:home_cleaning_marketplace/features/notifications/data/notification_models.dart';

class NotificationState {
  const NotificationState({
    required this.loading,
    this.loadingMore = false,
    this.saving = false,
    this.items = const <InboxNotification>[],
    this.nextCursor,
    this.unreadOnly = false,
    this.unreadCount = 0,
    this.errorMessage,
  });

  const NotificationState.loading()
    : loading = true,
      loadingMore = false,
      saving = false,
      items = const <InboxNotification>[],
      nextCursor = null,
      unreadOnly = false,
      unreadCount = 0,
      errorMessage = null;

  final bool loading;
  final bool loadingMore;
  final bool saving;
  final List<InboxNotification> items;
  final String? nextCursor;
  final bool unreadOnly;
  final int unreadCount;
  final String? errorMessage;

  NotificationState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? saving,
    List<InboxNotification>? items,
    String? nextCursor,
    bool? unreadOnly,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return NotificationState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      saving: saving ?? this.saving,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      unreadOnly: unreadOnly ?? this.unreadOnly,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationController extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    watchAuthIdentityKey(ref);
    if (!watchHasAuthSession(ref)) {
      return const NotificationState(loading: false);
    }
    return const NotificationState(loading: false);
  }

  NotificationApi get _api => ref.read(notificationApiProvider);

  Future<void> load({bool? unreadOnly}) async {
    if (!ref.mounted) {
      return;
    }
    final filter = unreadOnly ?? state.unreadOnly;
    state = NotificationState(
      loading: true,
      unreadOnly: filter,
      unreadCount: state.unreadCount,
    );
    try {
      final page = await _api.list(unread: filter ? true : null);
      final count = await _api.unreadCount();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        unreadOnly: filter,
        unreadCount: count,
        clearCursor: page.nextCursor == null,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = NotificationState(
        loading: false,
        unreadOnly: filter,
        unreadCount: state.unreadCount,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = NotificationState(
        loading: false,
        unreadOnly: filter,
        unreadCount: state.unreadCount,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!ref.mounted) {
      return;
    }
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingMore) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await _api.list(
        unread: state.unreadOnly ? true : null,
        after: cursor,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loadingMore: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> setUnreadFilter(bool unreadOnly) {
    return load(unreadOnly: unreadOnly);
  }

  Future<void> refreshUnreadCount() async {
    if (!ref.mounted) {
      return;
    }
    try {
      final count = await _api.unreadCount();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(unreadCount: count, loading: false);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false);
    }
  }

  Future<void> markOne(String notificationId) async {
    if (!ref.mounted || state.saving) {
      return;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final updated = await _api.markRead(notificationId);
      if (!ref.mounted) {
        return;
      }
      final wasUnread = state.items.any(
        (item) => item.id == notificationId && !item.isRead,
      );
      var items = [
        for (final item in state.items)
          if (item.id == updated.id) updated else item,
      ];
      if (state.unreadOnly) {
        items = [
          for (final item in items)
            if (!item.isRead) item,
        ];
      }
      state = state.copyWith(
        saving: false,
        items: items,
        unreadCount: wasUnread && state.unreadCount > 0
            ? state.unreadCount - 1
            : state.unreadCount,
      );
      await refreshUnreadCount();
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(saving: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        saving: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> markAll() async {
    if (!ref.mounted || state.saving) {
      return;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final remaining = await _api.markAllRead();
      if (!ref.mounted) {
        return;
      }
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        saving: false,
        unreadCount: remaining,
        items: state.unreadOnly
            ? const <InboxNotification>[]
            : [
                for (final item in state.items)
                  item.isRead ? item : item.copyWith(readAt: now),
              ],
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(saving: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        saving: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );
