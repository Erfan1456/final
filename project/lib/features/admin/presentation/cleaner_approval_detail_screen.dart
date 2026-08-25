import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_cleaner_review_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';

/// Administrator cleaner application detail.
class CleanerApprovalDetailScreen extends ConsumerStatefulWidget {
  const CleanerApprovalDetailScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<CleanerApprovalDetailScreen> createState() =>
      _CleanerApprovalDetailScreenState();
}

class _CleanerApprovalDetailScreenState
    extends ConsumerState<CleanerApprovalDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>(
      () => ref
          .read(adminCleanerReviewControllerProvider.notifier)
          .loadDetail(widget.userId),
    );
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve cleaner?'),
        content: const Text('Approve this pending cleaner application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(adminCleanerReviewControllerProvider.notifier)
          .approve(widget.userId);
    }
  }

  Future<void> _reject() async {
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectReasonDialog(),
    );
    final trimmed = submitted?.trim() ?? '';
    if (trimmed.runes.length < 5) {
      if (submitted != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reason must be at least 5 characters.'),
          ),
        );
      }
      return;
    }
    await ref
        .read(adminCleanerReviewControllerProvider.notifier)
        .reject(widget.userId, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCleanerReviewControllerProvider);
    final detail = state.detail;
    final profile = detail?.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Application detail')),
      body: SafeArea(
        child: state.loading && detail == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (state.errorMessage != null) Text(state.errorMessage!),
                  if (detail != null && profile != null) ...[
                    Text(profile.fullName),
                    Text(detail.email),
                    Text(profile.phoneE164 ?? 'No phone'),
                    Text(profile.bio),
                    Text('Experience: ${profile.yearsExperience} years'),
                    Text('Service area: ${profile.serviceArea}'),
                    Text('Status: ${profile.onboardingStatus.wireValue}'),
                    if (profile.submittedAt != null)
                      Text(
                        'Submitted: ${profile.submittedAt!.toIso8601String()}',
                      ),
                    if (profile.reviewedBy != null)
                      Text('Reviewed by: ${profile.reviewedBy}'),
                    if (profile.rejectionReason != null)
                      Text('Rejection: ${profile.rejectionReason}'),
                    if (profile.onboardingStatus ==
                        OnboardingStatus.pending) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: state.saving ? null : _approve,
                        child: const Text('Approve'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: state.saving ? null : _reject,
                        child: const Text('Reject'),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject cleaner'),
      content: TextField(
        controller: _reason,
        decoration: const InputDecoration(labelText: 'Reason'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
