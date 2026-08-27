import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/session_management_controller.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_confirmation_dialog.dart';

/// Lists and revokes signed-in account sessions.
class SessionManagementScreen extends ConsumerWidget {
  const SessionManagementScreen({super.key});

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _revokeSession(
    BuildContext context,
    SessionManagementController notifier,
    String sessionId,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Revoke session?',
      message: 'Sign out this device from your account?',
      confirmLabel: 'Revoke',
      isDestructive: true,
    );
    if (confirmed) {
      await notifier.revokeSession(sessionId);
    }
  }

  Future<void> _revokeCurrentSession(
    BuildContext context,
    SessionManagementController notifier,
    String sessionId,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'End this session?',
      message:
          'This will end your current session on this device. '
          'You will need to sign in again.',
      confirmLabel: 'End session',
      isDestructive: true,
    );
    if (confirmed) {
      await notifier.revokeSession(sessionId);
    }
  }

  Future<void> _revokeAll(
    BuildContext context,
    SessionManagementController notifier,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Sign out all devices?',
      message: 'This will sign out every device that can access your account.',
      confirmLabel: 'Sign out all',
      isDestructive: true,
    );
    if (confirmed) {
      await notifier.revokeAllSessions();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionManagementControllerProvider);
    final notifier = ref.read(sessionManagementControllerProvider.notifier);
    final submitting = state.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Active sessions')),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'These devices can access your account. Revoke any session you do not recognize.',
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (state.infoMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.infoMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (state.sessions.isEmpty)
                    const Text('No active sessions found.')
                  else
                    ...state.sessions.map((session) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            session.isCurrent
                                ? 'This device (current session)'
                                : 'Session ${session.id.substring(0, 8)}…',
                          ),
                          subtitle: Text(
                            'Created ${_formatTimestamp(session.createdAt)}\n'
                            'Expires ${_formatTimestamp(session.expiresAt)}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.logout),
                            tooltip: session.isCurrent
                                ? 'Revoke current session'
                                : 'Revoke session',
                            onPressed: submitting
                                ? null
                                : () => session.isCurrent
                                      ? _revokeCurrentSession(
                                          context,
                                          notifier,
                                          session.id,
                                        )
                                      : _revokeSession(
                                          context,
                                          notifier,
                                          session.id,
                                        ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: submitting || state.sessions.isEmpty
                        ? null
                        : () => _revokeAll(context, notifier),
                    child: submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign out all devices'),
                  ),
                ],
              ),
      ),
    );
  }
}
