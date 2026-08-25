import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_audit_log_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';

class AdminAuditDetailScreen extends ConsumerStatefulWidget {
  const AdminAuditDetailScreen({super.key, required this.auditLogId});

  final String auditLogId;

  @override
  ConsumerState<AdminAuditDetailScreen> createState() =>
      _AdminAuditDetailScreenState();
}

class _AdminAuditDetailScreenState
    extends ConsumerState<AdminAuditDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminAuditLogControllerProvider.notifier)
          .loadDetail(widget.auditLogId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAuditLogControllerProvider);
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Audit detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Audit log was not found.')
              : ListView(
                  children: [
                    Text(detail.action.label),
                    Text('Actor ${detail.actorUserId} (${detail.actorRole})'),
                    Text('${detail.targetType} ${detail.targetId}'),
                    Text(formatLocalDateTime(detail.createdAt)),
                    if (detail.reason != null) Text('Reason: ${detail.reason}'),
                    const SizedBox(height: 16),
                    const Text('Metadata'),
                    if (detail.metadata.isEmpty) const Text('None'),
                    for (final entry in detail.metadata.entries)
                      Text('${entry.key}: ${_formatScalar(entry.value)}'),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                  ],
                ),
        ),
      ),
    );
  }
}

String _formatScalar(Object? value) {
  if (value == null) {
    return '—';
  }
  if (value is String || value is int || value is bool) {
    return '$value';
  }
  return 'unsupported';
}
