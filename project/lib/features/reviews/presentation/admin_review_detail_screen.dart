import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/reviews/data/review_models.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/admin_review_controller.dart';

class AdminReviewDetailScreen extends ConsumerStatefulWidget {
  const AdminReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<AdminReviewDetailScreen> createState() =>
      _AdminReviewDetailScreenState();
}

class _AdminReviewDetailScreenState
    extends ConsumerState<AdminReviewDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminReviewControllerProvider.notifier)
          .loadDetail(widget.reviewId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReviewControllerProvider);
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Review moderation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Review was not found.')
              : ListView(
                  children: [
                    Text('Review ${detail.shortId}'),
                    Text('${detail.rating} ★'),
                    Text(detail.moderationStatus.label),
                    if (detail.comment != null) Text(detail.comment!),
                    Text('Booking ${detail.bookingId}'),
                    Text('Customer ${detail.customerUserId}'),
                    Text('Cleaner ${detail.cleanerUserId}'),
                    Text('Created ${formatLocalDateTime(detail.createdAt)}'),
                    if (detail.hiddenReason != null)
                      Text('Hidden reason: ${detail.hiddenReason}'),
                    if (detail.hiddenBy != null)
                      Text('Hidden by ${detail.hiddenBy}'),
                    if (detail.hiddenAt != null)
                      Text('Hidden ${formatLocalDateTime(detail.hiddenAt!)}'),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    const SizedBox(height: 16),
                    if (!detail.isHidden)
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => _openHideDialog(detail),
                        child: Text(state.saving ? 'Hiding...' : 'Hide Review'),
                      )
                    else
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => ref
                                  .read(adminReviewControllerProvider.notifier)
                                  .unhide(detail.id),
                        child: Text(
                          state.saving ? 'Unhiding...' : 'Unhide Review',
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openHideDialog(AdminReviewDetail detail) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _HideReviewDialog(),
    );
    if (!mounted || reason == null) {
      return;
    }
    await ref
        .read(adminReviewControllerProvider.notifier)
        .hide(reviewId: detail.id, reason: reason);
  }
}

class _HideReviewDialog extends StatefulWidget {
  const _HideReviewDialog();

  @override
  State<_HideReviewDialog> createState() => _HideReviewDialogState();
}

class _HideReviewDialogState extends State<_HideReviewDialog> {
  final _reason = TextEditingController();
  String _validation = '';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.length < 5 || reason.length > 500) {
      setState(() {
        _validation = 'Reason must be between 5 and 500 characters.';
      });
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hide review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _reason,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          if (_validation.isNotEmpty) Text(_validation),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Hide')),
      ],
    );
  }
}
